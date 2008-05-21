# == Schema Information
# Schema version: 20080506015153
#
# Table name: tasks
#
#  id           :integer         not null, primary key
#  title        :string(255)     not null
#  description  :string(255)     not null
#  priority     :integer(1)      not null
#  due_on       :date
#  status       :string(255)     not null
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
    self.status = attributes[:status] == 'reserved' ? 'reserved' : 'ready'
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
  STATUSES = ['reserved', 'ready', 'active', 'suspended', 'completed',
  'cancelled']

  # Cannot change in mass update.
  attr_protected :status
  validates_inclusion_of :status, :in=>STATUSES

  # Check method for each status (active?, completed?, etc).
  STATUSES.each do |status|
    define_method "#{status}?" do
      self.status == status
    end
  end

  before_validation_on_update do |task|
    task.status = 'ready' if task.status == 'reserved'
  end

  before_validation do |task|
    case task.status
    when 'ready', 'reserved'
      task.owner = task.potential_owners.first unless task.owner || task.potential_owners.size > 1
      task.status = 'active' if task.owner
    when 'active'
      task.status = 'ready' unless task.owner
    end
  end

  validate do |task|
    changes = task.changes['status']
    from, to = changes.first, changes.last if changes
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

  named_scope :pending, :conditions=>["tasks.status IN ('ready', 'active') AND involved.role IN ('owner', 'potential')"],
    :order=>'involved.role, priority ASC, tasks.created_at' do
    def prioritized
      today = Date.today
      prioritize = lambda { |task| [task.status == 'active' ? 0 : 1, task.due_on && task.due_on <= today ? task.due_on - today : 1, task.priority] }
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
 
  has_many :activities, :include=>[:task, :person], :order=>'activities.created_at DESC', :extend=>Activity::Grouping

  # Attribute recording person who created/modified this task.  Not persisted,
  # but used to log activities associated with this task.
  attr_accessor :modified_by

  before_save :unless=>lambda { |task| task.status == 'reserved' } do |task|
    Activity.log task, task.modified_by do |log|
      if task.changes['status']
        from, to = *task.changes['status']
        log.add task.creator, 'created' if task.creator && (from.nil? || from == 'reserved')
        log.add 'resumed' if from == 'suspended'
        case to
        when 'ready'
          log.add task.changes['owner'].first, 'released' if from == 'active'
        when 'active' then log.add task.owner, 'is owner of'
        when 'suspended' then log.add 'suspended'
        when 'completed' then log.add task.owner, 'completed'
        when 'cancelled' then log.add 'cancelled'
        end
      else
        log.add 'modified'
      end
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
