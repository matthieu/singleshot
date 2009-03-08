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
# Schema version: 20090206215123
#
# Table name: tasks
#
#  id                 :integer         not null, primary key
#  status             :string(255)     not null
#  title              :string(255)     not null
#  description        :string(255)
#  language           :string(5)
#  priority           :integer(1)      not null
#  due_on             :date
#  start_on           :date
#  cancellation       :string(255)
#  perform_integrated :boolean
#  view_integrated    :boolean
#  perform_url        :string(255)
#  view_url           :string(255)
#  data               :text            not null
#  hooks              :string(255)
#  access_key         :string(32)      not null
#  version            :integer         not null
#  created_at         :datetime
#  updated_at         :datetime
#
class Task < ActiveRecord::Base

  def initialize(*args, &block)
    super
    self[:status] = :available
    self[:priority] ||= DEFAULT_PRIORITY
    self[:access_key] = ActiveSupport::SecureRandom.hex(16)
  end

  attr_accessible :title, :description, :language, :priority, :due_on, :start_on, :stakeholders, :owner, :status, :data, :webhooks
  attr_readable   :title, :description, :language, :priority, :due_on, :start_on, :stakeholders, :status, :data,
                  :version, :created_at, :updated_at

  # -- Descriptive --
  # title, description, language

  validates_presence_of :title  # Title is required, description and language are optional


  # -- Urgency --
 
  PRIORITY = 1..5 # Priority ranges from 1 to 5, 1 is the highest priority.
  DEFAULT_PRIORITY = 3 # Default priority is 3.

  validates_inclusion_of :priority, :in=>PRIORITY

  
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

  # Stakeholders and people (as stakeholders) associated with this task.
  has_many :stakeholders, :include=>:person, :dependent=>:delete_all,
    :before_add=>:stakeholders_before_add, :before_remove=>:stakeholders_before_remove

  def stakeholders_with_supervisor_access=(list)
    raise ActiveRecord::RecordInvalid, self unless new_record? || in_role?(:supervisor, modified_by)
    self.stakeholders_without_supervisor_access = list
  end
  alias_method_chain :stakeholders=, :supervisor_access

  # Return all people associate with the specified role. For example:
  #   task.in_role(:observer)
  def in_role(role)
    stakeholders.select { |sh| sh.role == role }.map(&:person)
  end

  # Return all people associated with the specified roles. For example:
  #   task.in_roles(:owner, :potential)
  def in_roles(*roles)
    stakeholders.select { |sh| roles.include?(sh.role) }.map(&:person).uniq
  end

  # Return true if a person is associated with this task in a particular role. For example:
  #   task.in_role?(:owner, john)
  #   task.in_role?(:owner, "john.smith")
  def in_role?(role, identity)
    return false unless identity
    person = Person.identify(identity)
    stakeholders.any? { |sh| sh.role == role && sh.person == person }
  end

  def owner
    in_role(:owner).first
  end

  def owner=(person)
    person = Person.identify(person) if person
    unless person == owner
      stakeholders.delete stakeholders.select { |sh| sh.role == :owner }
      stakeholders.build :person=>person, :role=>:owner if person
    end
  end

  def stakeholders_before_add(sh)
    case sh.role
    when :creator
      errors.add :stakeholders, "Task cannot have two creators" unless in_role(:creator).empty?
    when :owner
      changed_attributes['owner'] ||= nil
      errors.add :stakeholders, "Excluded owner #{sh.person.to_param} cannot become task owner" if in_role?(:excluded_owner, sh.person)
      errors.add :stakeholders, "Task cannot have two owners" unless in_role(:owner).empty?
    when :potential_owner
      errors.add :stakeholders, "Excluded owner #{sh.person.to_param} cannot be potential owner" if in_role?(:excluded_owner, sh.person)
    end
    raise ActiveRecord::RecordInvalid, self if errors.on(:stakeholders)
  end

  def stakeholders_before_remove(sh)
    changed_attributes['owner'] = sh.person if sh.role == :owner
  end

  private :stakeholders_before_add, :stakeholders_before_remove

  before_save do |task|
    past_owner, owner = task.changes['owner']
    task.stakeholders.build :role=>:potential_owner, :person=>owner if owner && !task.in_role?(:potential_owner, owner)
    task.stakeholders.build :role=>:past_owner, :person=>past_owner if past_owner && !task.in_role?(:past_owner, past_owner)
  end

=begin
  def stakeholders=(list) #:nodoc: prevents delete/insert with no material update.
    returning stakeholders do |current|
      current.replace(list.map { |item| current.detect { |sh| sh.role == item.role && sh.person == item.person } || item })
    end
  end

  attr_accessible *Stakeholder::SINGULAR_ROLES

  # Task creator and owner.  Adds three methods for each role:
  # * {role}          -- Returns person associated with this role, or nil.
  # * {role}?(person) -- Returns true if person associated with this role.
  # * {role}= person  -- Assocaites person with this role (can be nil).
  Stakeholder::SINGULAR_ROLES.each do |role|
    define_method(role) { in_role(role).first }
    define_method("#{role}?") { |identity| in_role?(role, identity) }
    define_method "#{role}=" do |identity|
      attribute_will_change!(role)
      associate!(role=>identity.blank? ? nil : identity)
    end
    define_method("#{role}_changed?") { attribute_changed?(role) }
    define_method("#{role}_change") { attribute_change(role) }
  end
=end

=begin
  
  # Eager loading of stakeholders associated with each task.
  named_scope :with_stakeholders, :include=>{ :stakeholders=>:person }
  # Load only tasks that this person is a stakeholder of (owner, observer, etc).
  named_scope :for_stakeholder, lambda { |person|
    { :joins=>'JOIN stakeholders AS involved ON involved.task_id=tasks.id', :readonly=>false,
      :conditions=>["involved.person_id=? AND involved.role != 'excluded' AND tasks.status != 'reserved'", person.id] } }


  def creator_with_change_check=(creator)
    changed_attributes['creator'] = creator
    self.creator_without_change_check = creator if reserved? || new_record?
  end
  alias_method_chain :creator=, :change_check

  ACCESSOR_FROM_ROLE = { 'creator'=>'creator', 'owner'=>'owner', 'potential'=>'potential_owners', 'excluded'=>'excluded_owners',
                         'observer'=>'observers', 'admin'=>'admins' }

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

  validate do |task|
    # Can only have one member of a singular role.
    Stakeholder::SINGULAR_ROLES.each do |role|
      task.errors.add role, "Can only have one #{role}." if task.stakeholders.select { |sh| sh.role == role }.size > 1
    end
    task.errors.add :creator, 'Cannot change creator.' if task.creator_changed? && ![nil, 'reserved'].include?(task.status_was)
    task.errors.add :owner, "#{task.owner.fullname} is on the excluded owners list and cannot be owner of this task." if
      task.owner && task.excluded_owner?(task.owner)
    to, from = task.owner_change
    if task.potential_owners.empty?
      # With no potential owners, task must have a set owner.
      #task.errors.add :owner, "This task intended for one owner." unless task.owner || task.reserved?
    else
      # We have a limited set of potential owners, owner must be one of them.
      #task.errors.add :owner, "#{task.owner.fullname} is not allowd as owner of this task" unless task.owner && task.potential_owners?(task.owner)
    end
    conflicting = task.potential_owners & task.excluded_owners
    task.errors.add :potential_owners, "#{conflicting.map(&:fullname).join(', ')} listed on both excluded and potential owners list" unless
      conflicting.empty?
  end

=end


  # -- Data and reference --

  serialize :data

  def data #:nodoc:
    write_attribute(:data, Hash.new) if read_attribute(:data).blank?
    read_attribute(:data) || write_attribute(:data, Hash.new)
  end
  
  validate { |task| task.errors.add :data, "Must be a hash" unless Hash === task.data }


  # -- Status --

  # A task can report one of these statuses:
  # * available -- Task is available, can be claimed by owner.
  # * active    -- Task is active, performed by owner.
  # * suspended -- Task is suspended.
  # * completed -- Task has completed.
  # * cancelled -- Task was cancelled.
  STATUSES = [:available, :active, :suspended, :completed, :cancelled]

  symbolize :status, :in=>STATUSES

  # Check method for each status (active?, completed?, etc).
  STATUSES.each { |status| define_method("#{status}?") { self.status == status } }

  before_validation do |task|
    case task.status
    when :available
      # If we create the task with one potential owner, wouldn't it make sense to automatically assign it?
      if !task.owner && (potential = task.in_role(:potential_owner)) && potential.size == 1
        task.owner = potential.first
      end
      # Assigned task becomes active.
      task.status = :active if task.owner
    when :active
      # Unassigned task becomes available.
      task.status = :available unless task.owner
    end
  end

  def readonly? # :nodoc:
    [:completed, :cancelled].include?(status_was)
  end


  # -- Activities --

  has_many :activities, :include=>[:task, :person], :order=>'activities.created_at desc', :dependent=>:delete_all

  before_create do |task|
    creator = task.in_role(:creator).first
    task.modified_by ||= creator
    task.activities.build :name=>:created, :person=>creator  if creator
    task.activities.build :name=>:claimed, :person=>task.owner if task.owner
  end

  before_update do |task|
    past_owner, owner = task.changes['owner']
    if owner
      task.activities.build :name=>:delegated, :person=>task.modified_by  if task.modified_by && task.modified_by != owner
      task.activities.build :name=>:claimed, :person=>owner
    else
      task.activities.build :name=>:released, :person=>past_owner
    end

    if task.status_changed?
      case task.status
      when :active, :available
        task.activities.build :name=>:resumed, :person=>task.modified_by if task.status_was == 'suspended' && task.modified_by
      when :suspended
        task.activities.build :name=>:suspended, :person=>task.modified_by if task.modified_by
      when :completed
        task.activities.build :name=>:completed, :person=>task.owner
      when :cancelled
        task.activities.build :name=>:cancelled, :person=>task.modified_by if task.modified_by
      end
    end
  
    changed = task.changed - ['status', 'owner']
    task.activities.build :name=>:modified, :person=>task.modified_by unless changed.empty?
  end


  # -- Webhooks --
 
  has_many :webhooks, :dependent=>:delete_all


  # -- Access Control --

  # The person creating/updating this task.
  attr_accessor :modified_by
  
  # Returns true if this person can own the task. Potential owners and supervisors can own the task,
  # excluded owners cannot (even if they appear in the other list).
  def can_own?(person)
    (in_role?(:potential_owner, person) || in_role?(:supervisor, person)) && !in_role?(:excluded_owner, person)
  end

  validate_on_update do |task|
    by_supervisor = task.in_role?(:supervisor, task.modified_by)
    past_owner, owner = task.changes['owner']
    if past_owner != owner
      if owner
        task.errors.add :owner, "#{owner.to_param} is not allowed to claim task" unless task.can_own?(owner)
      end
      if past_owner # owned, so delegating to someone else
        task.errors.add :owner, "Only owner or supervisor can change ownership" unless task.modified_by == past_owner || by_supervisor
      end
    end

    if task.status_changed?
      case task.status_was
      when 'suspended'
        task.errors.add :status, "Only supervisor is allowed to resume this task" unless task.cancelled? || by_supervisor
      end

      case task.status
      when :available, :active
        task.errors.add :status, "Only supervisor is allowed to resume this task" if task.status_was == 'suspended' && !by_supervisor
      when :suspended
        task.errors.add :status, "Only supervisor is allowed to suspend this task" unless by_supervisor
      when :completed
        task.errors.add :status, "Only owner can complete task" unless task.owner == task.modified_by
      when :cancelled
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


  # -- View and perform ---

  # Some tasks are performed offline, for example, calling a customer.  Other
  # tasks performed onlined, in which case we would like to render that UI
  # component as part of the task view.
  #
  # There are two possible views for each task.  One view, presented to the
  # task owner for performing the task, the other view presented to everyone
  # else and only provides details about the task.
  #
  # Some UIs are integrated with the task manager: they obtain the task state
  # and update it upon completion.  Other UIs require that the user mark the
  # task upon completion.
  #
  # Tasks that do not have a UI representation (e.g. offline tasks) should use
  # the task description as the most adequate representation.  Calling
  # #render_url on these tasks returns nil.
  #
  # Tasks that do have a UI representation should use #perform_url when
  # performing the task, and #details_url for anyone else viewing the task.
  # However, offline tasks can just use #details_url for both, and UIs that
  # must not be accessible to anyone but the owner should use #perform_url
  # only, with description presented to everyone else.
  #
  # The method #render_url returns either #perform_url or #details_url to the
  # owner, and #details_url (or nil) to anyone else.
  #
  # UIs that integrate with the taske manager (#integrated_ui) will need
  # additional query parameters in the URL, those are passed to render_for
  # using an argument/block.  UIs that are not integrated should provide the
  # user with other means for marking the task as completed
  # (#use_completion_button?).
  class Rendering

    MAPPING = %w{perform_url details_url integrated_ui}.map { |name| [name, name] }
    attr_reader :perform_url, :details_url, :integrated_ui

    def initialize(perform_url, details_url, integrated_ui)
      @perform_url, @details_url = perform_url, details_url
      @integrated_ui = (perform_url && integrated_ui) || false
    end

    # True if rendering a button for user to mark task as completed.
    def use_completion_button?
      !perform_url || !integrated_ui
    end

    # Returns most suitable URL for rendering the task.
    #
    # Returns nil if there is no suitable URL for rendering the task,
    # otherwise, returns perform_url or details_url.  If the integrated_ui
    # option is available, passes query parameters to the rendered URL.  Query
    # parameters are passed as last argument or returned from the block.
    def render_url(perform, params = {})
      url = perform && perform_url || details_url
      return url unless integrated_ui && url
      params = yield if block_given?
      uri = URI(url)
      uri.query = CGI.parse(uri.query || '').update(params).to_query
      uri.to_s
    end

  end

  composed_of :rendering, :class_name=>Rendering.to_s, :mapping=>Rendering::MAPPING do |hash|
    Rendering.new(hash[:perform_url], hash[:details_url], hash[:integrated_ui])
  end

  validates_url :perform_url, :allow_nil=>true
  validates_url :details_url, :allow_nil=>true


  belongs_to :context


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

  # Returns a token allowing that particular person to access the task.
  # The token is validated by calling #authorize.  The token is only valid
  # if the person is a stakeholder in the task, and based on their role.
  def token_for(person)
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA.new, access_key, person.to_param)
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

  named_scope :pending, :limit=>5
  named_scope :with_stakeholders, :include=>{ :stakeholders=>:person }

  # Completed tasks only in reverse chronological order.
  named_scope :completed, :conditions=>"tasks.status = 'completed'", :order=>"tasks.updated_at desc"
  
  # Cancelled tasks only in reverse chronological order.
  named_scope :cancelled, :conditions=>"tasks.status = 'cancelled'", :order=>"tasks.updated_at desc"
end
