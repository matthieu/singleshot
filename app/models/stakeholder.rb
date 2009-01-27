# == Schema Information
# Schema version: 20080621023051
#
# Table name: stakeholders
#
#  id         :integer         not null, primary key
#  task_id    :integer         not null
#  person_id  :integer         not null
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
  SINGULAR_ROLES = [:creator, :owner]

  # A task will have multiple stakeholders in this role:
  # * potential_owner -- Person who is allowed to claim (become owner of) the task.
  # * excluded_owner  -- Person who is not allowed to claim the task.
  # * supervisor      -- Supervisors are allowed to modify the task, change its status, etc.
  # * observer        -- Watches and receives notifications about the task.
  PLURAL_ROLES = [:potential_owner, :excluded_owner, :observer, :supervisor]

  ALL_ROLES = SINGULAR_ROLES + PLURAL_ROLES

  # Stakeholder associated with a task.
  belongs_to :task
  validates_presence_of :task

  # Stakeholder associated with a person.
  belongs_to :person
  validates_presence_of :person

  # Role for this stakeholder.
  def role
    self[:role].to_sym if self[:role]
  end
  def role=(role)
    self[:role] = role && role.to_s
  end
  validates_inclusion_of :role, :in=>ALL_ROLES
  validates_uniqueness_of :role, :scope=>[:task_id, :person_id]

  def readonly?
    !new_record?
  end

end
