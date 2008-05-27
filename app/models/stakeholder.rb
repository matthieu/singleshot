# == Schema Information
# Schema version: 20080506015153
#
# Table name: stakeholders
#
#  id         :integer         not null, primary key
#  task_id    :integer
#  person_id  :integer
#  role       :string(255)     not null
#  created_at :datetime        not null
#

# Represents a stakeholder in the task.  Identifies the person and their role.
# Some roles allow multiple people, others do not.  This distinction is handled by
# the Task itself.
class Stakeholder < ActiveRecord::Base

  # A task will only have one stakeholder in this role:
  # * creator         -- Person who created the task, specified at creation.
  # * owner           -- Person who currently owns (performs) the task.
  SINGULAR_ROLES = ['creator', 'owner']

  # A task will have multiple stakeholders in this role:
  # * potential -- Person who is allowed to claim (become owner of) the task.
  # * excluded  -- Person who is not allowed to claim the task.
  # * admin     -- Admins are allowed to modify the task, change its status, etc.
  # * observer  -- Watches and receives notifications about the task.
  PLURAL_ROLES = ['potential', 'excluded', 'observer', 'admin']

  # All supported roles.
  ROLES = SINGULAR_ROLES + PLURAL_ROLES

  # Stakeholder associated with a task.
  belongs_to :task

  # Stakeholder associated with a person.
  belongs_to :person
  validates_presence_of :person

  # Role for this stakeholder.
  validates_inclusion_of :role, :in=>ROLES

  validates_uniqueness_of :role, :scope=>[:task_id, :person_id]


  # Task creator and owner.  Adds three methods for each role:
  # * {role}          -- Returns person associated with this role, or nil.
  # * {role}?(person) -- Returns true if person associated with this role.
  # * {role}= person  -- Assocaites person with this role (can be nil).
  module Accessors

    SINGULAR_ROLES.each do |role|
      define_method(role) { in_role(role).first }
      define_method("#{role}?") { |identity| in_role?(role, identity) }
      define_method("#{role}=") { |identity| set_role role, identity }
    end

    def creator=(identity)
      return unless new_record?
      set_role 'creator', identity
    end

    ACCESSORS = { 'potential_owner'=>'potential', 'excluded_owner'=>'excluded', 'observer'=>'observer', 'admin'=>'admin' }
    ACCESSORS.each do |accessor, role|
      plural = accessor.pluralize
      define_method(plural) { in_role(role) }
      define_method("#{accessor}?") { |identity| in_role?(role, identity) }
      define_method("#{plural}=") { |identities| set_role role, identities }
    end

    # Returns true if person is a stakeholder in this task: any role except excluded owners list.
    def stakeholder?(person)
      stakeholders.any? { |sh| sh.person_id == person.id && sh.role != 'excluded' }
    end

  private

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
      new_set = Array(identities).map { |id| Person.identify(id) }
      old_set = stakeholders.select { |sh| sh.role == role }
      stakeholders.delete old_set.reject { |sh| new_set.include?(sh.person) }
      (new_set - old_set.map(&:person)).each { |person| stakeholders.build :person=>person, :role=>role }
      changed_attributes[role] = old_set.first if SINGULAR_ROLES.include?(role.to_s) && !changed_attributes.has_key?(role)
    end

  end


  module Validation
    def self.included(base)
      base.before_validation_on_create do |record|
        record.owner = record.potential_owners.first unless record.owner || record.potential_owners.size > 1
      end

      # Can only have one member of a singular role.
      SINGULAR_ROLES.each do |role|
        base.validate do |record|
          record.errors.add role, "Can only have one #{role}." if record.stakeholders.select { |sh| sh.role == role }.size > 1
        end
      end
      base.validate do |record|
        creator = record.stakeholders.detect { |sh| sh.role == 'creator' }
        record.errors.add :creator, 'Cannot change creator.' if record.changed.include?(:creator) && !record.new_record?
        record.errors.add :owner, "#{record.owner.fullname} is on the excluded owners list and cannot be owner of this task." if
          record.excluded_owner?(record.owner)
        conflicting = record.potential_owners & record.excluded_owners
        record.errors.add :potential_owners, "#{conflicting.map(&:fullname).join(', ')} listed on both excluded and potential owners list" unless
          conflicting.empty?
      end
    end
  end

end
