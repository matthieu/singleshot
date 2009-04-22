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

  #
  # -- Stakeholders --

  # Stakeholders and people (as stakeholders) associated with this task.
  has_many :stakeholders, :include=>:person, :dependent=>:delete_all, :foreign_key=>'task_id',
    :before_add=>:stakeholders_before_add, :before_remove=>:stakeholders_before_remove

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

  cattr_accessor :singular_roles
  cattr_accessor :plural_roles

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
    attr_readonly *roles

    roles.each do |role|
      singular = role.singularize
      if singular == role # singular role (creator, owner)

        write_inheritable_attribute :singular_roles, Set.new(role) + (read_inheritable_attribute(:singular_roles) || [])
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

        write_inheritable_attribute :plural_roles, Set.new(role) + (read_inheritable_attribute(:plural_roles) || [])
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
 
  def stakeholders_before_add(sh)
    if self.class.read_inheritable_attribute(:singular_roles).include?(sh.role)
      errors.add :stakeholders, "Task cannot have two #{sh.role}" unless in_role(sh.role).empty?
    end
    raise ActiveRecord::RecordInvalid, self if errors.on(:stakeholders)
  end

  def stakeholders_before_remove(sh)
  end
  private :stakeholders_before_add, :stakeholders_before_remove



  def template?
    false
  end

end
