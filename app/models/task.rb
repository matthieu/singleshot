# == Schema Information
# Schema version: 20080506015153
#
# Table name: tasks
#
#  id              :integer         not null, primary key
#  title           :string(255)     not null
#  description     :string(255)     not null
#  priority        :integer(1)      not null
#  due_on          :date
#  status          :string(255)     not null
#  perform_url     :string(255)
#  details_url     :string(255)
#  form_completing :boolean
#  outcome_url     :string(255)
#  outcome_type    :string(255)
#  access_key      :string(32)
#  data            :text            not null
#  version         :integer         default(0), not null
#  created_at      :datetime
#  updated_at      :datetime
#

require 'openssl'
require 'md5'


class Task < ActiveRecord::Base

  def initialize(attributes = {}) #:nodoc:
    super
    self.description ||= ''
    self.data ||= {}
    self.access_key = MD5.hexdigest(OpenSSL::Random.random_bytes(128))
  end

  def to_param #:nodoc:
    id && id.to_s + ('-' + title).gsub(/[^\w]+/, '-').gsub(/-{2,}/, '-').sub(/-+$/, '')
  end

  # Locking column used for versioning and detecting update conflicts.
  set_locking_column 'version'

  # Returns an ETag that can identify changes to the task state.  No two tasks will have
  # the same ETag.  Changing the task state will also change its ETag.
  def etag
    MD5.hexdigest("#{id}:#{version}")
  end


  # --- Task status ---

  # A task can report one of these statuses:
  # * reserved  -- Task exists but is not yet ready or active.
  # * ready     -- Task is ready and can be claimed by owner.
  # * active    -- Task is performed by its owner.
  # * suspended -- Task is suspended.
  # * completed -- Task has completed.
  # * cancelled -- Task was cancelled.
  
  # A task can start as reserved and remain there until populated with enough
  # information to transition to ready.  From ready, a stakeholder can claim
  # the task, transitioning it to active.  The task transitions back to ready
  # if stakeholder releases that claim.
  #
  # Task can transition from ready/active to suspended and back.  Task can
  # transition to completed only from active, and transition to cancelled from
  # any other state but completed.  Completed and cancelled are terminal
  # states.
  STATUSES = ['reserved', 'ready', 'active', 'suspended', 'completed', 'cancelled']


  # Cannot change in mass update.
  validates_inclusion_of :status, :in=>STATUSES

  # Check method for each status (active?, completed?, etc).
  STATUSES.each do |status|
    define_method "#{status}?" do
      self.status == status
    end
  end

  before_validation do |task|
    # Default status is ready.
    task.status ||= 'ready' if task.new_record?
    case task.status
    when 'ready'
      # When task first created, if we only have one potential owner, pick them as owner.
      task.owner = task.potential_owners.first unless task.owner || task.potential_owners.size > 1
      # Assigned task => active.
      task.status = 'active' if task.owner
    when 'active'
      # Unassigned task => ready.
      task.status = 'ready' unless task.owner
    when 'completed', 'cancelled'
      # Cannot modify completed/cancelled tasks.
      task.readonly! unless task.status_changed?
    end
  end

  validate do |task|
    # Check state transitions.
    from, to = task.status_change
    if from == 'completed' 
      task.errors.add :status, 'Cannot change status of completed task.'
    elsif from == 'cancelled'
      task.errors.add :status, 'Cannot change status of cancelled task.'
    elsif to == 'reserved'
      task.errors.add :status, 'Cannot change status to reserved.' unless from.nil?
    elsif to == 'completed'
      task.errors.add :status, 'Only owner can complete task.' unless task.owner
      task.errors.add :status, 'Cannot change to completed from any status but active.' unless from =='active'
    end
  end


  # -- Common task attributes --

  validates_presence_of :title


  # -- View and perform ---

  # Some tasks are performed offline, for example, calling a customer.  Other
  # tasks are performed online, in which case we would like to include the UI
  # for performing the task as part of the task page.
  #
  # There are two views for each task.  One view presented to the task owner
  # for performing the task, the other view, presented to everyone else only
  # provides details about the task.
  #
  # Some forms are integrated with the task manager, these know how to update
  # the task status and mark the task as completed.  For all other forms, we
  # need to include a button to mark the task as completed.
  #
  # We handle these cases through several combinations of rendering
  # information.  Some tasks are rendered using only the task description (e.g.
  # offline tasks).  Other tasks provide a URL for performing the task, using
  # the description for everyone else.  Last, some tasks provide both a URL for
  # performing the task and a URL for viewing task details.
  class Rendering

    MAPPING = [%w{perform_url perform_url}, %w{details_url details_url}, %w{form_completing completing}]
    attr_reader :perform_url, :details_url, :completing

    def initialize(perform_url, details_url, completing)
      @perform_url = perform_url
      @details_url = details_url if perform_url
      @completing = perform_url && completing || false
    end

    # True if rendering the task using only the task description.
    def use_description?(performing)
      performing ? perform_url.nil? : details_url.nil?
    end

    # True if we need to include button to mark task as completed.
    def use_completion_button?
      !perform_url || !completing
    end

  end

  composed_of :rendering, :class_name=>Rendering.to_s, :mapping=>Rendering::MAPPING do |hash|
    Rendering.new(hash[:perform_url], hash[:details_url], hash[:completing])
  end

  validates_url :perform_url, :allow_nil=>true
  validates_url :details_url, :allow_nil=>true


  # --- Task data ---

  serialize :data
  before_validation do |record|
    record.data ||= {}
  end

  validate do |record|
    record.errors.add :data, 'Must be a hash' unless Hash === record.data
  end


  # --- Stakeholders ---
  
  # Stakeholders and people (as stakeholders) associated with this task.
  has_many :stakeholders, :include=>:person, :dependent=>:delete_all
  attr_protected :stakeholders

  # Eager loading of stakeholders associated with each task.
  named_scope :with_stakeholders, :include=>{ :stakeholders=>:person }
  # Load only tasks that this person is a stakeholder of (owner, observer, etc).
  named_scope :for_stakeholder, lambda { |person|
    { :joins=>'JOIN stakeholders AS involved ON involved.task_id=tasks.id', :readonly=>false,
      :conditions=>["involved.person_id=? AND involved.role != 'excluded' AND tasks.status != 'reserved'", person.id] } }

  # Task creator and owner.  Adds three methods for each role:
  # * {role}          -- Returns person associated with this role, or nil.
  # * {role}?(person) -- Returns true if person associated with this role.
  # * {role}= person  -- Assocaites person with this role (can be nil).
  Stakeholder::SINGULAR_ROLES.each do |role|
    define_method(role) { in_role(role).first }
    define_method("#{role}?") { |identity| in_role?(role, identity) }
    define_method "#{role}=" do |identity|
      old_value = in_role(role)
      new_value = set_role(role, identity)
      changed_attributes[role] = old_value unless changed_attributes.has_key?(role) || old_value == new_value
    end
  end

  def creator=(identity)
    return creator unless new_record?
    set_role 'creator', identity
  end

  ACCESSOR_FROM_ROLE = { 'potential'=>'potential_owners', 'excluded'=>'excluded_owners', 'observer'=>'observers', 'admin'=>'admins' }
  ACCESSOR_FROM_ROLE.default = lambda { |role| role }

  # Task observer, admins and potential/excluded owner.  Adds three methods for each role:
  # * {plural}            -- Returns people associated with this role.
  # * {singular}?(person) -- Returns true if person associated with this role.
  # * {plural}= people    -- Assocaites people with this role.
  Stakeholder::PLURAL_ROLES.each do |role|
    accessor = ACCESSOR_FROM_ROLE[role]
    define_method(accessor) { in_role(role) }
    define_method("#{accessor.singularize}?") { |identity| in_role?(role, identity) }
    define_method("#{accessor}=") { |identities| set_role role, identities }
  end

  # Returns true if person is a stakeholder in this task: any role except excluded owners list.
  def stakeholder?(person)
    stakeholders.any? { |sh| sh.person_id == person.id && sh.role != 'excluded' }
  end

  # Return all people in this role.
  def in_role(role)
    stakeholders.select { |sh| sh.role == role }.map(&:person)
  end

  # Return true if person in this role.
  def in_role?(role, identity)
    person = Person.identify(identity)
    stakeholders.any? { |sh| sh.role == role && sh.person == person }
  end

  # Set people associated with this role.
  def set_role(role, identities)
    new_set = [identities].flatten.compact.map { |id| Person.identify(id) }
    keeping = stakeholders.select { |sh| sh.role == role }
    stakeholders.delete keeping.reject { |sh| new_set.include?(sh.person) }
    (new_set - keeping.map(&:person)).each { |person| stakeholders.build :person=>person, :role=>role }
    return new_set
  end

  # Can only have one member of a singular role.
  validate do |record|
    Stakeholder::SINGULAR_ROLES.each do |role|
      record.errors.add role, "Can only have one #{role}." if record.stakeholders.select { |sh| sh.role == role }.size > 1
    end
  end

  validate do |record|
    creator = record.stakeholders.detect { |sh| sh.role == 'creator' }
    record.errors.add :creator, 'Cannot change creator.' if record.changed.include?(:creator) && !record.new_record?
    record.errors.add :owner, "#{record.owner.fullname} is on the excluded owners list and cannot be owner of this task." if
      record.excluded_owner?(record.owner)
    conflicting = record.potential_owners & record.excluded_owners
    record.errors.add :potential_owners, "#{conflicting.map(&:fullname).join(', ')} listed on both excluded and potential owners list" unless
      conflicting.empty?
  end


  # --- Priority and ordering ---
  
  # Task priority: 1 is the highest, 3 the lowest, average is the default.
  PRIORITIES = 1..3
  validates_inclusion_of :priority, :in=>PRIORITIES
  before_validation do |task|
    task.priority ||= (PRIORITIES.min + PRIORITIES.max) >> 1
  end

  def high_priority?
    priority == PRIORITIES.min
  end

  def over_due?
    due_on ? due_on < Date.today : false
  end

  # Scopes can use this to add ranking methods on returned records.
  module RankingMethods

    # Tasks are ranked by the following rules:
    # - Tasks you're performing (owner of) always rank higher than all other tasks.
    # - Tasks available to you rank higher than tasks not available to you
    # - Over due tasks always rank higher than today's tasks
    # - And today's tasks always rank higher than task with no due date
    # - High priority tasks always rank higher than lower priority tasks
    # - Older tasks rank higher than more recently created tasks
    def rank_for(person)
      today = Date.today
      # Calculating an absolute rank value is tricky if not impossible, so instead we construct
      # an array of values and compare these arrays against each other.  To create an array we
      # need a person's name, so we can ranked their owned tasks higher.
      rank = lambda { |task|
        [ person == task.owner ? 1 : 0, task.can_claim?(person) ? 1 : 0,
          (task.due_on && task.due_on <= today) ? today - task.due_on : -1,
          -task.priority, today - task.created_at.to_date ] }
      self.sort { |a,b| rank[b] <=> rank[a] }
    end

  end


  # --- Activities ---
 
  has_many :activities, :include=>[:task, :person], :order=>'activities.created_at DESC'

  # Associate person with all modifications done on this task.
  # This results in activities linked to the person and task when
  # the task is saved.
  def modified_by(person)
    @modified_by = person
    self
  end

  LOG_CHANGE_ATTRIBUTES = [:title, :description, :priority, :due_on]

  before_save :unless=>lambda { |task| task.status == 'reserved' } do |task|
    task.log_activities do |log|
      if task.status_changed?
        from, to = task.status_change
        log.add task.creator, 'created' if from.nil? || from == 'reserved'
        case to
        when 'ready'
          log.add nil, 'resumed' if from == 'suspended'
          log.add nil, 'released' if from == 'active'
        when 'active'
          log.add nil, 'resumed' if from == 'suspended'
          log.add task.owner, 'is owner of' if task.changed.include?('owner')
        when 'suspended' then log.add nil, 'suspended'
        when 'completed' then log.add task.owner, 'completed'
        when 'cancelled' then log.add nil, 'cancelled'
        end
      elsif task.changed.include?('owner')
        # TODO: get this working!
        log.add task.owner, 'is owner of'
      elsif task.changed.any? { |attr| LOG_CHANGE_ATTRIBUTES.include?(attr) }
        log.add nil, 'changed'
      end
    end
  end

  def log_activities
    log = Hash.new
    def log.add(person, action)
      self[person] = Array(self[person]).push(action)
    end
    yield log
    log.each do |person, actions|
      activities.build :person=>person || @modified_by, :action=>actions.to_sentence
    end
  end
  

  # --- Completion and cancellation ---

  validates_url :outcome_url, :if=>:outcome_url

  # Supported formats for updating the outcome resource.
  OUTCOME_MIME_TYPES = [Mime::JSON, Mime::XML]

  before_validation { |task| task.outcome_type = nil unless task.outcome_url }
  before_validation { |task| task.outcome_type ||= Mime::XML if task.outcome_url }
  validates_inclusion_of :outcome_type, :in=>OUTCOME_MIME_TYPES, :if=>:outcome_url,
    :message=>"Supported MIME types are #{OUTCOME_MIME_TYPES.to_sentence}"

  # Sets the outcome content type.
  def outcome_type=(mime_type)
    self[:outcome_type] = case mime_type
      when Mime::Type;     mime_type.to_s
      when /^\w+\/\w+$/;   mime_type.downcase
      when Symbol, String; Mime::EXTENSION_LOOKUP[mime_type.to_s.downcase].to_s
      when nil;            nil
      else raise ArgumentError, 'Unsupported MIME type #{mime_type}'
    end
  end

  def completed_on
    # TODO: should be attribute
  end

  def complete!(data = nil)
    self.status = :completed
    self.data = data if data
    # TODO: Update outcome, observers
    save!
  end

  def cancel!
    if reserved?
      destroy
    else
      self.status = :cancelled
      # TODO: Update outcome, observers
      save!
    end
  end



  # --- Access control ---

  enumerable :cancellation, [:admin, :owner], :default=>:admin

  # Returns true if this person can cancel this task.
  def can_cancel?(person)
    return false if completed? || cancelled?
    #return true if person.admin? || admin?(person)
    #return owner?(person) if cancellation == :owner
    return true if admin?(person)
    false
  end

  # Returns true if this person can complete this task.
  def can_complete?(person)
    active? && owner?(person)
  end

  def can_suspend?(person)
    admin?(person) && active? || ready? # || person.admin?
  end

  def can_claim?(person)
    owner.nil? && potential_owner?(person)
  end

  def can_delegate?(person)
    (owner?(person) && active?) || (admin?(person) && active? || ready?)
  end

  def filter_update_for(person)
    if admin?(person) || person.admin?
      # Administrator can change anything, but make sure to retain as administrator,
      # and limit status change to active/suspended.
      lambda { |attrs|
        status = attrs[:status].to_s
        attrs.update(:suspended=> status == 'suspended') if ['active', 'suspended'].include?(status)
        attrs.update(:admins=>Array(attrs[:admins]) << person) }
    elsif active?
      if owner?(person)
        # Owner is allowed to change ownership and task data, but only release if there
        # are other potential owners.  Owner also allowed to change task data.
        lambda { |attrs|
          released = attrs.has_key?(:owner) && attrs[:owner].blank?
          attrs.slice!(:owner, :data) unless released && (potential_owners - [owner]).empty? }
      elsif potential_owner?(person)
        # Potential owner allowed to claim unclaimed task.
        lambda { |attrs|
          attrs.slice!(:owner) if person.same_as?(attrs[:owner]) && owner.nil? }
      end
    end
  end

  attr_protected :access_key

  # Returns a token allowing that particular person to access the task.
  # The token is validated by calling #authorize.  The token is only valid
  # if the person is a stakeholder in the task, and based on their role.
  def token_for(person)
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, access_key, person.to_param)
  end

  # Returns the person authorized to access this task based on the token returned
  # by #token_for.  The person is guaranteed to be a stakeholder in the task.
  # Returns nil if the token is invalid or the person is no longer associated with
  # this task.
  def authenticate(token)
    ['owner', 'creator', 'admin', 'observer', 'potential_owner'].map { |role| in_role(role) }.flatten.
      find { |person| token_for(person) == token }
  end



  # --- Finders and named scopes ---

  # Pending tasks are:
  # - Active tasks owned by the person
  # - Ready tasks that can be claimed by the person
  named_scope :pending, :joins=>'JOIN stakeholders AS involved ON involved.task_id=tasks.id',
    :conditions=>["(tasks.status = 'ready' AND involved.role = 'potential') OR (tasks.status = 'active' AND involved.role = 'owner')"],
    :extend=>RankingMethods

  named_scope :completed, lambda { |end_date|
    { :conditions=>["tasks.status == 'completed' AND tasks.updated_at >= ?", end_date || Date.today - 7.days],
      :order=>'tasks.updated_at DESC' } }

  named_scope :following, lambda { |end_date|
    { :conditions=>["tasks.updated_at >= ?", end_date || Date.today - 7.days],
      :order=>'tasks.updated_at DESC' } }

  named_scope :visible, :conditions=>["tasks.status != 'reserved'"]
end
