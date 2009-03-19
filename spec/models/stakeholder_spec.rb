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
describe Stakeholder do
  subject { Stakeholder.make }

  it { should belong_to(:person) }
  it { should validate_presence_of(:person) }
  it { should belong_to(:task) }
  it { should have_attribute(:role) }
  it { should have_db_column(:role, :type=>:string) }
  it { should validate_presence_of(:role) }
  it { should validate_inclusion_of(:role, :in=>['creator', 'owner']) }
  it { should validate_inclusion_of(:role, :in=>['potential_owner', 'excluded_owner', 'past_owner']) }
  it { should validate_inclusion_of(:role, :in=>['supervisor', 'observer']) }
  it { should have_attribute(:created_at) }
  it { should have_db_column(:created_at, :type=>:datetime) }
  it { should validate_uniqueness_of(:role, :scope=>[:task_id, :person_id]) }
end
