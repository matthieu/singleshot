# Singleshot  Copyright (C) 2008-2009  Intalio, Inc
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


require 'openssl'


# == Schema Information
# Schema version: 20090421005807
#
# Table name: tasks
#
#  id           :integer(4)      not null, primary key
#  status       :string(255)     not null
#  title        :string(255)     not null
#  description  :string(255)
#  language     :string(5)
#  priority     :integer(1)      not null
#  due_on       :date
#  start_on     :date
#  cancellation :string(255)
#  data         :text            default(""), not null
#  hooks        :string(255)
#  access_key   :string(32)      not null
#  version      :integer(4)      not null
#  created_at   :datetime
#  updated_at   :datetime
#  type         :string(255)     not null
#
class Task < Base

  def initialize(args = nil, &block)
    super
    self[:status] = 'available'
    self[:access_key] = ActiveSupport::SecureRandom.hex(16)
  end

  attr_accessible :status, :due_on, :start_on
  attr_readable   :title, :description, :language, :priority, :due_on, :start_on, :status, :data, :version, :created_at, :updated_at



  # -- Urgency --
 
  def over_due?
    # due_on ? (ready? || active?) && due_on < Date.current : false
  end
=begin
  
  # If t-0 is the due date for this task, return days past deadline as positive
  # number, calculated so one wee 
  #
  # This only applies to tasks with due date that are ready or active, all
  # other tasks return nil.
  #
  # T-0 is the task's due date.  If we're past that due date, return a positive
  # value that is over-due / 7 (i.e. week over due = 1.0).
  #
  # If we're ahead of the due date, and there is no specified start date,
  # return a negative value that is days-left / 7 (i.e. week left = -1.0).
  #
  # If we do have a start by date, return a negative value indicating progress,
  # starting with -1.0 on the start date and working all the way up to 0 on the
  # due date.
  def deadline
    return unless due_on && (ready? || active?)
    today = Date.current
    return (today - due_on).to_f / 7 if due_on < today
    (today - due_on).to_f * (due_on - (start_by || today - 1.week)).to_f
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
      today = Date.current
      # Calculating an absolute rank value is tricky if not impossible, so instead we construct
      # an array of values and compare these arrays against each other.  To create an array we
      # need a person's name, so we can ranked their owned tasks higher.
      rank = lambda { |task|
        [ person == task.owner ? 1 : 0, task.can_claim?(person) ? 1 : 0,
          (task.due_on && task.due_on <= today) ? today - task.due_on : -1,
          -task.priority, today - task.created_at.to_date ] }
        # involved.role <> 'owner'
        # tasks.priority, tasks.created_at
      self.sort { |a,b| rank[b] <=> rank[a] }
    end

  end

=end

  # -- Stakeholders --

  stakeholders 'owner', 'creator', 'potential_owners', 'excluded_owners', 'past_owners', 'supervisors', 'observers'
  attr_readonly :creator

  ['owner', 'creator'].each do |role|
    define_method(role) { in_role(role).first }
    define_method("#{role}?") { |identity| in_role?(role, identity) }
    define_method "#{role}=" do |identity|
      person = Person.identify(identity) if identity
      unless person == send(role)
        stakeholders.delete stakeholders.select { |sh| sh.role == role }
        stakeholders.build :person=>person, :role=>role if person
      end
    end
  end

  def stakeholders_before_add(sh)
    super
    case sh.role
    when 'owner'
      changed_attributes['owner'] ||= nil
      errors.add :owner, "Excluded owner #{sh.person.to_param} cannot become task owner" if excluded_owner?(sh.person)
      past_owner, new_owner = changes['owner']
      errors.add :owner, "Only owner or supervisor can change ownership" unless
        (modified_by && modified_by.can_change?(self)) || past_owner.nil? || modified_by == past_owner
    when 'potential_owner'
      errors.add :stakeholders, "Excluded owner #{sh.person.to_param} cannot be potential owner" if excluded_owner?(sh.person)
      stakeholders_supervisor_check
    when 'past_owner'
    else
      stakeholders_supervisor_check
    end
    raise ActiveRecord::RecordInvalid, self if errors.on(:stakeholders) || errors.on(:owner)
  end

  def stakeholders_before_remove(sh)
    super
    if sh.role == 'owner'
      errors.add :owner, "Only owner or supervisor can change ownership" unless modified_by && modified_by.can_delegate?(self)
      changed_attributes['owner'] = sh.person
    else
      stakeholders_supervisor_check
    end
    raise ActiveRecord::RecordInvalid, self if errors.on(:stakeholders) || errors.on(:owner)
  end

  def stakeholders_supervisor_check
    unless new_record? || (modified_by && modified_by.can_change?(self))
      errors.add :stakeholders, "Only supervisor allowed to change stakeholders"
    end
  end
  private :stakeholders_supervisor_check

  before_save do |task|
    past_owner, owner = task.changes['owner']
    task.stakeholders.build :role=>'potential_owner', :person=>owner if owner && !task.potential_owner?(owner)
    task.stakeholders.build :role=>'past_owner', :person=>past_owner if past_owner && !task.past_owner?(past_owner)
  end


  # -- Status --

  # A task can report one of these statuses:
  # * available -- Task is available, can be claimed by owner.
  # * active    -- Task is active, performed by owner.
  # * suspended -- Task is suspended.
  # * completed -- Task has completed.
  # * cancelled -- Task was cancelled.
  STATUSES = ['available', 'active', 'suspended', 'completed', 'cancelled']

  validates_inclusion_of :status, :in=>STATUSES

  # Check method for each status (active?, completed?, etc).
  STATUSES.each { |status| define_method("#{status}?") { self.status == status } }

  before_validation do |task|
    case task.status
    when 'available'
      # If we create the task with one potential owner, wouldn't it make sense to automatically assign it?
      if !task.owner && (potential = task.potential_owners) && potential.size == 1
        task.owner = potential.first
      end
      # Assigned task becomes active.
      task.status = 'active' if task.owner
    when 'active'
      # Unassigned task becomes available.
      task.status = 'available' unless task.owner
    end
  end

  def readonly? # :nodoc:
    ['completed', 'cancelled'].include?(status_was)
  end


  # -- Activities --

  has_many :activities, :include=>[:task, :person], :order=>'activities.created_at desc', :dependent=>:delete_all

  before_create do |task|
    creator = task.creator
    task.modified_by ||= creator
    task.activities.build :name=>'created', :person=>creator  if creator
    task.activities.build :name=>'claimed', :person=>task.owner if task.owner
  end

  before_update do |task|
    past_owner, owner = task.changes['owner']
    if owner
      task.activities.build :name=>'delegated', :person=>task.modified_by  if task.modified_by && task.modified_by != owner
      task.activities.build :name=>'claimed', :person=>owner
    else
      task.activities.build :name=>'released', :person=>past_owner
    end

    if task.status_changed?
      case task.status
      when 'active', 'available'
        task.activities.build :name=>'resumed', :person=>task.modified_by if task.status_was == 'suspended' && task.modified_by
      when 'suspended'
        task.activities.build :name=>'suspended', :person=>task.modified_by if task.modified_by
      when 'completed'
        task.activities.build :name=>'completed', :person=>task.owner
      when 'cancelled'
        task.activities.build :name=>'cancelled', :person=>task.modified_by if task.modified_by
      end
    end
  
    changed = task.changed - ['status', 'owner']
    task.activities.build :name=>'modified', :person=>task.modified_by unless changed.empty?
  end


  # -- Access Control --

  # The person creating/updating this task.
  attr_accessor :modified_by
  
  # Returns true if this person can own the task. Potential owners and supervisors can own the task,
  # excluded owners cannot (even if they appear in the other list).
  def can_own?(person)
    (potential_owners.empty? || potential_owner?(person) || supervisor?(person)) && !excluded_owner?(person)
  end

  validate_on_update do |task|
    by_supervisor = task.supervisor?(task.modified_by)

    if task.status_changed?
      case task.status_was
      when 'suspended'
        task.errors.add :status, "Only supervisor is allowed to resume this task" unless task.cancelled? || by_supervisor
      end

      case task.status
      when 'available', 'active'
        task.errors.add :status, "Only supervisor is allowed to resume this task" if task.status_was == 'suspended' && !by_supervisor
      when 'suspended'
        task.errors.add :status, "Only supervisor is allowed to suspend this task" unless by_supervisor
      when 'completed'
        task.errors.add :status, "Only owner can complete task" unless task.owner == task.modified_by
      when 'cancelled'
        task.errors.add :status, "Only supervisor allowed to cancel this task" unless by_supervisor
      end
    end

    unless by_supervisor
      # Supervisors can change anything, owners only data, status is looked at separately. 
      changed = task.changed - ['status', 'owner']
      changed -= ['data'] if task.owner == task.modified_by
      unless changed.empty?
        task.errors.add_to_base "You are not allowed to change the attributes #{changed.to_sentence}"
      end
    end
  end


  # Locking column used for versioning and detecting update conflicts.
  set_locking_column 'version'

  def clone
    returning super do |clone|
      stakeholders.each do |sh|
        clone.stakeholders.build :role=>sh.role, :person=>sh.person
      end
      clone.form = form.clone if form
    end
  end


=begin
  def to_param #:nodoc:
    id && id.to_s + ('-' + title).gsub(/[^\w]+/, '-').gsub(/-{2,}/, '-').sub(/-+$/, '')
  end

  # Returns an ETag that can identify changes to the task state.  No two tasks will have
  # the same ETag.  Changing the task state will also change its ETag.
  def etag
    SHA1.hexdigest("#{id}:#{version}")
  end



  # --- Access control ---

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
    { :conditions=>["tasks.status = 'completed' AND tasks.updated_at >= ?", end_date || Date.current - 7.days],
      :order=>'tasks.updated_at DESC' } }

  named_scope :following, lambda { |end_date|
    { :conditions=>["tasks.updated_at >= ?", end_date || Date.current - 7.days],
      :order=>'tasks.updated_at DESC' } }

  named_scope :visible, :conditions=>["tasks.status != 'reserved'"]

=end

  named_scope :pending, :joins=>'JOIN stakeholders AS involved ON involved.task_id=tasks.id',
    :conditions=>["(tasks.status = 'ready' AND involved.role = 'potential') OR (tasks.status = 'active' AND involved.role = 'owner')"] # TODO: spec this
  named_scope :with_stakeholders, :include=>{ :stakeholders=>:person }

  # Completed tasks only in reverse chronological order.
  named_scope :completed, :conditions=>"tasks.status = 'completed'", :order=>"tasks.updated_at desc"
  
  # Cancelled tasks only in reverse chronological order.
  named_scope :cancelled, :conditions=>"tasks.status = 'cancelled'", :order=>"tasks.updated_at desc"
end
