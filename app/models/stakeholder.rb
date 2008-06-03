# == Schema Information
# Schema version: 20080506015153
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
  SINGULAR_ROLES = ['creator', 'owner']

  # A task will have multiple stakeholders in this role:
  # * potential -- Person who is allowed to claim (become owner of) the task.
  # * excluded  -- Person who is not allowed to claim the task.
  # * admin     -- Admins are allowed to modify the task, change its status, etc.
  # * observer  -- Watches and receives notifications about the task.
  PLURAL_ROLES = ['potential', 'excluded', 'observer', 'admin']

  ALL_ROLES = SINGULAR_ROLES + PLURAL_ROLES

  # Stakeholder associated with a task.
  belongs_to :task

  # Stakeholder associated with a person.
  belongs_to :person
  validates_presence_of :person

  # Role for this stakeholder.
  validates_inclusion_of :role, :in=>ALL_ROLES
  validates_uniqueness_of :role, :scope=>[:task_id, :person_id]

  def readonly?
    !new_record?
  end

end
