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

  before_validation_on_create do |task|
    if task.owner
      # Owner should always be allowed as potential owner.
      task.stakeholders.build :role=>'potential_owner', :person=>task.owner if !task.potential_owner?(task.owner)
    else
      # If we create the task with one potential owner, wouldn't it make sense to automatically assign it?
      potential = task.potential_owners
      task.owner = potential.first if potential.size == 1
    end
  end

  validate do |task|
    if task.changed.include?('owner')
      past_owner, new_owner = task.changes['owner']
      task.errors.add 'owner', "#{new_owner.to_param} cannot perform this task" if new_owner && !task.can_own?(new_owner)
      if task.new_record? || task.modified_by.nil? || task.modified_by.can_change?(task)
        # Anyone accepted as owner during task creation or when assigned by supervisor.
      elsif task.modified_by == past_owner # Delegated by owner. Owner can delegate to anyone (incl. no one).
      elsif task.modified_by == new_owner  # New owner claiming task.
        task.errors.add 'owner', "You cannot claim task from someone else" if past_owner
      else # Someone else trying to delegate class.
        task.errors.add 'owner', "Only owner or supervisor can delegate task"
      end
    end
    if task.changed.include?('potential_owners')
      task.potential_owners.each do |potential|
        task.errors.add 'potential_owners', "Excluded owner #{potential.to_param} cannot be potential owner" if task.excluded_owner?(potential)
      end
    end

    unless task.new_record? || (task.modified_by && task.modified_by.can_change?(task)) || (task.plural_roles & task.changed).empty?
      task.errors.add 'stakeholders', "Only supervisor allowed to change stakeholders"
    end
  end

  after_validation_on_update do |task|
    # Likewise, owner should always appear as potential owner. Previous owner also listed as past_owner.
    past_owner, new_owner = task.changes['owner']
    task.stakeholders.create :role=>'potential_owner', :person=>new_owner if new_owner && !task.potential_owner?(new_owner)
    task.stakeholders.create :role=>'past_owner', :person=>past_owner if past_owner && !task.past_owner?(past_owner)
  end


  # -- Status --

  # A task can report one of these statuses:
  # * available -- Task is available, can be claimed by owner.
  # * active    -- Task is active, performed by owner.
  # * suspended -- Task is suspended.
  # * completed -- Task has completed.
  # * cancelled -- Task was cancelled.
  statuses 'available', 'active', 'suspended', 'completed', 'cancelled'

  before_validation do |task|
    if task.available?
      task.status = 'active' if task.owner
    elsif task.active?
      task.status = 'available' unless task.owner
    end
  end

  def readonly? # :nodoc:
    ['completed', 'cancelled'].include?(status_was)
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


  # -- Activity --

  before_create do |task|
    task.modified_by ||= task.creator
  end

  after_create do |task|
    task.log! task.creator, 'task.created' if task.creator
  end

  after_save do |task|

    changed = task.changed
    if changed.delete('owner')
      past_owner, owner = task.changes['owner']
      if owner
        task.log! owner, 'task.claimed' 
      else
        task.log! past_owner, 'task.released' 
      end
      changed.delete('past_owners')
    end

    if changed.delete('status')
      case task.status
      when 'active', 'available'
        task.log! task.modified_by, 'task.resumed' if task.status_was == 'suspended' && task.modified_by
      when 'suspended'
        task.log! task.modified_by, 'task.suspended' if task.modified_by
      when 'completed'
        task.log! task.owner, 'task.completed' 
      when 'cancelled'
        task.log! task.modified_by, 'task.cancelled'  if task.modified_by
      end
    end
  end

  after_update do |task|
    if task.changed.include?('owner') && task.owner && task.modified_by != task.owner
      task.log! task.modified_by, 'task.delegated' if task.modified_by
    end
    changed = task.changed - ['owner', 'past_owners', 'status', 'updated_at', 'version']
    task.log! task.modified_by, 'task.modified' unless changed.empty? || task.modified_by.nil?
  end

  def log!(person, name) # :nodoc:
    super
    event = name.split('.').last
    webhooks.select { |hook| hook.event == event }.each(&:send_notification)
  end


  # Locking column used for versioning and detecting update conflicts.
  set_locking_column 'version'


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
=end

  named_scope :pending, :joins=>'JOIN stakeholders AS involved ON involved.task_id=tasks.id',
    :conditions=>["(tasks.status = 'available' AND involved.role = 'potential_owner') OR (tasks.status = 'active' AND involved.role = 'owner')"] # TODO: spec this
  named_scope :with_stakeholders, :include=>{ :stakeholders=>:person }

  # Completed tasks only in reverse chronological order.
  named_scope :completed, :conditions=>"tasks.status = 'completed'", :order=>"tasks.updated_at desc"
  
  # Cancelled tasks only in reverse chronological order.
  named_scope :cancelled, :conditions=>"tasks.status = 'cancelled'", :order=>"tasks.updated_at desc"

  named_scope :in_the_past, lambda { |days| { :conditions=>['tasks.updated_at >= ?', Date.today - days] } }
end
