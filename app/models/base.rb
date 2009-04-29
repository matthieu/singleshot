class Base < ActiveRecord::Base

  def initialize(*args, &block)
    super
    self[:priority] ||= DEFAULT_PRIORITY
  end

  set_table_name 'tasks'

  # -- Descriptive --
  # title, description, language

  attr_accessible :title, :description, :language
  validates_presence_of :title  # Title is required, description and language are optional

  # -- Priority --
  PRIORITY = 1..3 # Priority ranges from 1 to 3, 1 is the highest priority.
  DEFAULT_PRIORITY = 2 # Default priority is 2.

  attr_accessible :priority
  validates_inclusion_of :priority, :in=>PRIORITY


  # -- Status --

  attr_accessible :status
  validates_presence_of :status

  # Check method for each status (active?, completed?, etc).
  # Use this to declare which statuses are available for this model. It validates inclusion
  # and also defines check methods (e.g. active?, enabled?)
  def self.statuses(*names)
    names.each { |status| define_method("#{status}?") { self.status == status } }
    validates_inclusion_of :status, :in=>names
  end


  # -- Data and meta-data --

  serialize :data
  attr_accessible :data

  def data #:nodoc:
    write_attribute(:data, Hash.new) if read_attribute(:data).blank?
    read_attribute(:data) || write_attribute(:data, Hash.new)
  end
  
  validate { |task| task.errors.add :data, "Must be a hash" unless Hash === task.data }


  # -- Presentation --

  has_one :form, :dependent=>:delete, :foreign_key=>'task_id'
  attr_accessible :form

  def form_with_hash_typecase=(form) #:nodoc:
    self.build_form form
  end
  alias_method_chain :form=, :hash_typecase


  # -- Webhooks --
 
  has_many :webhooks, :dependent=>:delete_all, :foreign_key=>'task_id'
  attr_accessible :webhooks

  def webhooks_with_hash_mapping=(hooks) #:nodoc:
    self.webhooks_without_hash_mapping = hooks.map { |hook| Webhook === hook ? hook : Webhook.new(hook) }
  end
  alias_method_chain :webhooks=, :hash_mapping

  
  # -- Stakeholders --

  # Stakeholders and people (as stakeholders) associated with this task.
  has_many :stakeholders, :include=>:person, :dependent=>:delete_all, :foreign_key=>'task_id',
    :before_add=>:stakeholder_change!, :before_remove=>:stakeholder_change!
  

  # Return all people associate with the specified role. For example:
  #   task.in_role('observer')
  def in_role(role)
    stakeholders.select { |sh| sh.role == role }.map(&:person)
  end

  # Return all people associated with the specified roles. For example:
  #   task.in_roles('owner', 'potential')
  def in_roles(*roles)
    stakeholders.select { |sh| roles.include?(sh.role) }.map(&:person).uniq
  end

  # Return true if a person is associated with this task in a particular role. For example:
  #   task.in_role?('owner', john)
  #   task.in_role?('owner', "john.smith")
  def in_role?(role, identity)
    return false unless identity
    person = Person.identify(identity)
    stakeholders.any? { |sh| sh.role == role && sh.person == person }
  end

  # Returns all singular roles defined for this model (e.g. creator, owner).
  def singular_roles
    self.class.read_inheritable_attribute(:singular_roles) || []
  end

  # Returns all plural roles defined for this model (e.g. supervisors, observers).
  def plural_roles
    self.class.read_inheritable_attribute(:plural_roles) || []
  end

  # Use these to add new stakeholder accessors. For singular roles adds the accessors:
  # * {role}              -- Returns stakeholder in that role
  # * {role}= person      -- Assigns person to that role
  # * {role}?(person)     -- Checks if person is in that role.
  # For plural roles, adds the accessors:
  # * {plural}            -- Returns people associated with this role.
  # * {singular}?(person) -- Returns true if person associated with this role.
  # * {plural}= people    -- Assocaites people with this role.
  def self.stakeholders(*roles)
    attr_accessible *roles

    roles.each do |role|
      singular = role.singularize
      if singular == role # singular role (creator, owner)

        write_inheritable_attribute :singular_roles, (read_inheritable_attribute(:singular_roles) || Set.new) << role
        define_method(role) { in_role(role).first }
        define_method("#{role}?") { |identity| in_role?(role, identity) }
        define_method "#{role}=" do |identity|
          person = Person.identify(identity) if identity
          unless person == send(role)
            stakeholders.delete stakeholders.select { |sh| sh.role == role }
            stakeholders.build :person=>person, :role=>role if person
          end
        end

      else # plural role (potential_owners, supervisors)

        write_inheritable_attribute :plural_roles, (read_inheritable_attribute(:plural_roles) || Set.new) << role
        define_method(role) { in_role(singular) }
        define_method("#{singular}?") { |identity| in_role?(singular, identity) }
        define_method "#{role}=" do |identities|
          stakeholders.delete stakeholders.select { |sh| sh.role == singular }
          Person.identify(Array(identities)).each do |person|
            stakeholders.build :person=>person, :role=>singular
          end
        end

      end
    end
  end
 
  validate do |record|
    record.singular_roles.each do |role|
      record.errors.add role, "Task cannot have two #{role.pluralize}" if record.in_role(role).size > 1
    end
  end

  def stakeholder_change!(sh)
    role = singular_roles.include?(sh.role) ? sh.role : sh.role.pluralize
    changed_attributes[role] ||= __send__(role)
  end


  # -- Access control --

  # The person creating/updating this object.
  attr_accessor :modified_by

  module ModifiedByOwner
    # Initialize the object on behalf of its creator. For example:
    #   creator = Person.find(authenticated)
    #   creator.tasks.new(attributes)
    def new(attributes = {}, &block)
      proxy_reflection.klass.new attributes do |object|
        yield object if block_given?
        object.stakeholders.build :role=>'creator', :person=>proxy_owner unless object.creator
        object.stakeholders.build :role=>'supervisor', :person=>proxy_owner if object.supervisors.empty?
      end
    end

    # Create the object on behalf of its creator. For example:
    #   creator = Person.find(authenticated)
    #   creator.tasks.create(attributes)
    def create(attributes = {}, &block)
      self.new(attributes, &block).tap(&:save)
    end

    # Similar to #create but throws RecordNotSaved if it fails to create a new record.
    def create!(attributes = {}, &block)
      self.new(attributes, &block).tap(&:save!)
    end
    
    # Use this to find object and update it on behalf of this person. For example:
    #   task = owner.tasks.find(task_id)
    #   task.update_attributes :status=>'completed'
    def find(*args)
      super.tap do |found|
        Array(found).each do |object|
          object.modified_by = proxy_owner
        end
      end
    end
  end 
  

  # -- Activity --

  has_many :activities, :include=>[:task, :person], :foreign_key=>'task_id', :order=>'activities.created_at DESC',  :dependent=>:delete_all

  # Log activity associated with this record. For example:
  #   task.log! owner, 'task.created'
  def log!(person, name)
    if new_record?
      activities.build :person=>person, :name=>name, :task=>self
    else
      activities.create :person=>person, :name=>name, :task=>self
    end
  end

end
