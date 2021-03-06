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

  attr_accessible :task, :person, :role
  attr_readable :person, :role

  # Stakeholder associated with a task.
  belongs_to :task
  belongs_to :template, :foreign_key=>'task_id'
  belongs_to :notification, :foreign_key=>'task_id'

  # Stakeholder associated with a person.
  belongs_to :person
  validates_presence_of :person

  validates_presence_of :role
  validates_uniqueness_of :role, :scope=>[:task_id, :person_id]

end
