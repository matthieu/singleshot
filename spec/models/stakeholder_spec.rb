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


require File.dirname(__FILE__) + '/helpers'


# == Schema Information
# Schema version: 20090421005807
#
# Table name: stakeholders
#
#  id         :integer(4)      not null, primary key
#  person_id  :integer(4)      not null
#  task_id    :integer(4)      not null
#  role       :string(255)     not null
#  created_at :datetime        not null
#
describe Stakeholder do
  subject { Stakeholder.make }

  should_belong_to :person
  should_validate_presence_of :person
  should_belong_to :task
  should_have_attribute :role
  should_have_column :role, :type=>:string
  should_validate_presence_of :role
  should_have_attribute :created_at
  should_have_column :created_at, :type=>:datetime
  should_validate_uniqueness_of :role, :scope=>[:task_id, :person_id]
end
