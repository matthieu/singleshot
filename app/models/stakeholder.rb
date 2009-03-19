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


# Represents a stakeholder in the task.  Identifies the person and their role.
# Some roles allow multiple people, others do not.  This distinction is handled by
# the Task itself.
#
#
# == Schema Information
# Schema version: 20090206215123
#
# Table name: stakeholders
#
#  id         :integer         not null, primary key
#  person_id  :integer         not null
#  task_id    :integer         not null
#  role       :string(255)     not null
#  created_at :datetime        not null
#
class Stakeholder < ActiveRecord::Base

  # A task will only have one stakeholder in this role:
  # * creator         -- Person who created the task, specified at creation.
  # * owner           -- Person who currently owns (performs) the task.
  SINGULAR_ROLES = [:creator, :owner]

  # A task will have multiple stakeholders in this role:
  # * potential_owner -- Person who is allowed to claim (become owner of) the task.
  # * excluded_owner  -- Person who is not allowed to claim the task.
  # * past_owner      -- Previous but no longer owner of the task.
  # * supervisor      -- Supervisors are allowed to modify the task, change its status, etc.
  # * observer        -- Watches and receives notifications about the task.
  PLURAL_ROLES = [:potential_owner, :excluded_owner, :past_owner, :observer, :supervisor]

  ROLES = SINGULAR_ROLES + PLURAL_ROLES
  
  attr_accessible :task, :person, :role
  attr_readonly :task, :person, :role

  # Stakeholder associated with a task.
  belongs_to :task

  # Stakeholder associated with a person.
  belongs_to :person
  validates_presence_of :person

  symbolize :role, :in=>ROLES
  validates_presence_of :role
  validates_uniqueness_of :role, :scope=>[:task_id, :person_id]

end
