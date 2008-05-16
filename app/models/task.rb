# == Schema Information
# Schema version: 20080506015153
#
# Table name: tasks
#
#  id           :integer         not null, primary key
#  title        :string(255)     not null
#  description  :string(255)     not null
#  priority     :integer(1)      default(1), not null
#  due_on       :date
#  state        :string(255)     not null
#  frame_url    :string(255)
#  outcome_url  :string(255)
#  outcome_type :string(255)
#  access_key   :string(32)
#  data         :text            not null
#  version      :integer         default(0), not null
#  created_at   :datetime
#  updated_at   :datetime
#

require 'openssl'
require 'md5'

class Task < ActiveRecord::Base

  def initialize(attributes = {}) #:nodoc:
    super
    self.description ||= ''
    self.state = attributes[:state] == 'ready' ? 'ready' : 'reserved'
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


  # --- Task state ---

  # A task can be in one of these states:
  # - reserved  -- Task exists but is not yet ready or active.
  # - ready     -- Task is ready and can be claimed by owner.
  # - active    -- Task is performed by its owner.
  # - suspended -- Task is suspended.
  # - completed -- Task has completed.
  # - cancelled -- Task was cancelled.
  #
  # A task can start in reserved state and remain there until populated with
  # enough information to transition to the ready state.  From ready state, a
  # stakeholder can claim the task, transitioning it to the active state.  The
  # task transitions back to ready if stakeholder releases that claim.
  #
  # Task can transition from ready/active to suspended and back.  Task can
  # transition to completed state only from active state, and transition to
  # cancelled state from any other state but completed.  Completed and
  # cancelled are terminal states.
  STATES = ['reserved', 'ready', 'active', 'suspended', 'completed', 'cancelled']

  # Cannot change in mass update.
  attr_protected :state
  validates_inclusion_of :state, :in=>STATES

  STATES.each do |state|
    define_method "#{state}?" do
      self.state == state
    end
  end

  before_validation_on_update do |task|
    task.state = 'ready' if task.state == 'reserved'
  end

  before_validation do |task|
    case task.state
    when 'ready', 'reserved'
      task.owner = task.potential_owners.first unless task.owner || task.potential_owners.size > 1
      task.state = 'active' if task.owner
    when 'active'
      task.state = 'ready' unless task.owner
    end
  end

  validate do |task|
    changes = task.changes['state']
    from, to = changes.first, changes.last if changes
    if from == 'completed' 
      task.errors.add :state, 'Cannot change state of completed task.'
    elsif from == 'cancelled'
      task.errors.add :state, 'Cannot change state of cancelled task.'
    elsif to == 'reserved'
      task.errors.add :state, 'Cannot change state to reserved.' unless from.nil?
    elsif to == 'completed'
      task.errors.add :state, 'Only owner can complete task.' unless task.owner
      task.errors.add :state, 'Cannot change to completed from any state but active.' unless from =='active'
    end
  end

  def status
    state
  end



  # -- Common task attributes --
  #

  validates_presence_of :title, :frame_url
  validates_url :frame_url, :if=>:frame_url

  # -- View and perform ---


  # --- Task data ---

  def data
    return self[:data] if Hash === self[:data]
    self[:data] = ActiveSupport::JSON.decode(self[:data] || '')
  end

  def data=(data)
    raise ArgumentError, 'Must be a hash or nil' unless Hash === data || data.nil?
    self[:data] = data || {}
  end

  before_save do |task|
    task[:data] = task[:data].to_json if task[:data]
  end


  # --- Stakeholders ---
  
  # Stakeholders and people (as stakeholders) associated with this task.
  has_many :stakeholders, :include=>:person, :dependent=>:delete_all
  attr_protected :stakeholders
 
  include Stakeholder::Accessors
  include Stakeholder::Validation

  named_scope :with_stakeholders, :include=>{ :stakeholders=>:person }

  named_scope :for_stakeholder, lambda { |person|
    { :joins=>'JOIN stakeholders AS involved ON involved.task_id=tasks.id', :conditions=>['involved.person_id=?', person.id], :include=>:stakeholders }
  }
  named_scope :for_owner,       lambda { |person|
    { :joins=>:stakeholders, :conditions=>["stakeholders.person_id=? and stakeholders.role='owner'", person.id] }
  }

  named_scope :pending, :conditions=>["tasks.state IN ('ready', 'active') AND involved.role IN ('owner', 'potential')"],
    :order=>'involved.role, priority ASC, tasks.created_at' do
    def prioritized
      today = Date.today
      prioritize = lambda { |task| [task.state == 'active' ? 0 : 1, task.due_on && task.due_on <= today ? task.due_on - today : 1, task.priority] }
      self.sort { |a, b| prioritize[a] <=> prioritize[b] }
    end
  end


  # --- Priority and ordering ---
  
  # Task priority: 1 is the highest, 3 the lowest, average is the default.
  PRIORITIES = 1..3
  before_validation { |task| task.priority ||= (PRIORITIES.min + PRIORITIES.max) >> 1 }
  validates_inclusion_of :priority, :in=>PRIORITIES

  def over_due?
    due_on && due_on < Date.today
  end


  # --- Activities ---

  after_save do |task|
    task.activities =  Activity.from_changes_to(task) unless task.state == 'reserved'
  end

  attr_accessor :activities

  def save(person = nil)
    super
    activities.each do |activity|
      activity.task = self
      activity.person ||= person
      activity.save if activity.person
    end if activities
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
    return false if state == 'completed' || state == 'cancelled'
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
    admin?(person) # || person.admin?
  end

  def can_claim?(person)
    owner.nil? && potential_owner?(person)
  end

  def can_assign_to?(person)
    !excluded_owner?(person)
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
  def authorize(token)
    (stakeholders.map { |sh| sh.person } + [owner, creator].compact).uniq.find { |person| token_for(person) == token }
  end

end
