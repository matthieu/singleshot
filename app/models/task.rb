# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with this
# work for additional information regarding copyright ownership.  The ASF
# licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.


# == Schema Information
# Schema version: 20090121220044
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
#  access_key         :string(40)      not null
#  version            :integer         not null
#  created_at         :datetime
#  updated_at         :datetime
#


require 'sha1'
require 'openssl'


class Task < ActiveRecord::Base

  def initialize(*args, &block)
    super
    self[:priority] ||= DEFAULT_PRIORITY
    self[:data] ||= {}
    self[:access_key] = SHA1.hexdigest(OpenSSL::Random.random_bytes(128))
  end



  # -- Descriptive --

  attr_accessible :title, :description, :language
  validates_presence_of :title  # Title is required, description and language are optional


  # -- Urgency --
 
  PRIORITY = 1..5 # Priority ranges from 1 to 5, 1 is the highest priority.
  DEFAULT_PRIORITY = 3 # Default priority is 3.

  attr_accessible :priority, :due_on, :start_on
  validates_inclusion_of :priority, :in=>PRIORITY

  
=begin
  


  def over_due?
    due_on ? (ready? || active?) && due_on < Date.current : false
  end

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
  attr_accessible :stakeholders, :owner

  # Return all people associate with the specified role. For example:
  #   task.in_role(:observer)
  def in_role(role)
    stakeholders.select { |sh| sh.role == role }.map(&:person)
  end

  # Return true if a person is associated with this task in a particular role. For example:
  #   task.in_role?(:owner, john)
  #   task.in_role?(:owner, "john.smith")
  def in_role?(role, identity)
    return false unless identity
    person = Person.identify(identity)
    stakeholders.any? { |sh| sh.role == role && sh.person == person }
  end

  # Associate peoples with roles. Returns self. For example:
  #   task.associate :owner=>"john.smith"
  #   task.associate :observer=>observers
  # Note: all previous associations with the given role are replaced.
  def associate(map)
    map.each do |role, identities|
      new_set = [identities].flatten.compact.map { |id| Person.identify(id) }
      keeping = stakeholders.select { |sh| sh.role == role }
      stakeholders.delete keeping.reject { |sh| new_set.include?(sh.person) }
      (new_set - keeping.map(&:person)).each { |person| stakeholders.build :person=>person, :role=>role }
    end
    self
  end

  # Similar to #associate but calls save! and return true if saved.
  def associate!(map)
    associate map
    save!
  end

  def owner
    in_role(:owner).first
  end

  def owner=(owner)
    associate :owner=>owner
  end

  def stakeholders_before_add(sh)
    if sh.role == :owner
      errors.add :owner, "Potential owners can only assign task to themselves" unless
        in_role?(:potential_owner, sh.person) || in_role?(:supervisor, updated_by)
      errors.add :owner, "Cannot assign task to excluded owner" if in_role?(:excluded_owner, sh.person)
      errors.add :owner, "Task cannot have two owners" unless in_role(:owner).empty?
    end
    raise ActiveRecord::RecordInvalid, self if errors.on(:owner)
  end

  def stakeholders_before_remove(sh)
    # Only owner/supervisor can assign to someone else.
    errors.add :owner, "Only owner or supervisor can change ownership" if sh.role == :owner &&
      !(sh.person == updated_by || in_role?(:supervisor, updated_by))
    raise ActiveRecord::RecordInvalid, self if errors.on(:owner)
  end

  private :stakeholders_before_add, :stakeholders_before_remove


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

  attr_accessible :data
  serialize :data, Hash
  validate { |record| record.errors.add :data, "Must be a hash" unless Hash === record.data }

  def data=(data) #:nodoc:
    write_attribute :data, data.blank? ? {} : data
  end


  # -- Status --

  # A task can report one of these statuses:
  # * available -- Task is available, can be claimed by owner.
  # * active    -- Task is active, performed by owner.
  # * suspended -- Task is suspended.
  # * completed -- Task has completed.
  # * cancelled -- Task was cancelled.
  STATUSES = [:available, :active, :suspended, :completed, :cancelled]

  symbolize :status, :in=>STATUSES
  attr_accessible :status

  # Check method for each status (active?, completed?, etc).
  STATUSES.each { |status| define_method("#{status}?") { self.status == status } }

  before_validation do |task|
    task.status ||= :available
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

  validate do |task|
    # Check state transitions.
    from, to = task.status_change
    from = from.to_sym if from
    case from
    when :suspended
      task.errors.add :status, "Only supervisor is allowed to resume this task" unless task.in_role?(:supervisor, task.updated_by) || task.cancelled?
    when :completed, :cancelled
      task.errors.add :status, "Cannot change status of #{from} task"
    end
    case to
    when :suspended
      task.errors.add :status, "Only supervisor is allowed to suspend this task" unless task.in_role?(:supervisor, task.updated_by)
    when :completed
      task.errors.add :status, "Can only complete task if currently active" unless from == :active
      task.errors.add :status, "Only owner can complete task" unless task.in_role?(:owner, task.updated_by)
    when :cancelled
      task.errors.add :status, "Only supervisor is allowed to cancel this task" unless task.in_role?(:supervisor, task.updated_by)
    end
  end

  def readonly? # :nodoc:
    [:completed, :cancelled].include?(status_was)
  end



  attr_reader :updated_by
  def update_by(person)
    @updated_by = person
    self
  end
  after_save { |task| task.update_by(nil) }

  # Locking column used for versioning and detecting update conflicts.
  set_locking_column 'version'

  def clone
    returning super do |clone|
      clone.stakeholders = stakeholders.map(&:clone)
    end
  end


  



=begin
  def initialize(attributes = {}) #:nodoc:
    super
    self.description ||= ''
    self.data ||= {}
  end

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


  # --- Activities ---

  has_many :activities, :include=>[:task, :person], :order=>'activities.created_at DESC', :dependent=>:delete_all

  def log_activity(person, name)
    person ||= modified_by
    activities.build :person=>person, :name=>name if person
  end

  LOG_CHANGE_ATTRIBUTES = [:title, :description, :priority, :due_on]

  before_save do |task|
    if task.status_changed?
      from, to = task.status_change
      task.log_activity task.creator, 'created' if from.nil? || from == 'reserved'
      case to
      when 'ready'
        task.log_activity nil, 'resumed' if from == 'suspended'
        task.log_activity nil, 'released' if from == 'active'
      when 'active'
        task.log_activity nil, 'resumed' if from == 'suspended'
        task.log_activity task.owner, 'owner' if task.changed.include?('owner')
      when 'suspended' then task.log_activity nil, 'suspended'
      when 'completed' then task.log_activity task.owner, 'completed'
      when 'cancelled' then task.log_activity nil, 'cancelled'
      end
    elsif task.changed.include?('owner')
      # TODO: get this working!
      task.log_activity task.owner, 'owner'
    elsif task.changed.any? { |attr| LOG_CHANGE_ATTRIBUTES.include?(attr) }
      task.log_activity nil, 'updated'
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

  # Person who is modifying this task: required to activity logging and access control.
  attr_reader :modified_by

  # Changes the modified_by person and return self.
  def modify_by(person)
    @modified_by = person
    self
  end

  after_save do |task|
    task.modify_by nil
  end


#  enumerable :cancellation, [:admin, :owner], :default=>:admin

  def can_cancel?(person)
    admin?(person) && !completed? && !cancelled?
  end

  def can_complete?(person)
    active? && owner?(person)
  end

  def can_suspend?(person)
    admin?(person) && (active? || ready? || suspended?)
  end

  def can_claim?(person)
    owner.nil? && (potential_owners.empty? || potential_owner?(person)) && !excluded_owner?(person)
  end

  def can_delegate?(person)
    (owner?(person) && active? && !(potential_owners - [owner]).empty?) || (admin?(person) && (active? || ready?))
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
    { :conditions=>["tasks.status = 'completed' AND tasks.updated_at >= ?", end_date || Date.current - 7.days],
      :order=>'tasks.updated_at DESC' } }

  named_scope :following, lambda { |end_date|
    { :conditions=>["tasks.updated_at >= ?", end_date || Date.current - 7.days],
      :order=>'tasks.updated_at DESC' } }

  named_scope :visible, :conditions=>["tasks.status != 'reserved'"]

=end
end
