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
  describe 'new' do
    subject { Stakeholder.make_unsaved }

    it { should belong_to(:person, Person) }
    it { should validate_presence_of(:person) }

    it { should belong_to(:task, Task) }

    it { should have_attribute(:role, :string, :null=>false) }
    it { should validate_presence_of(:role) }
    it { should validate_inclusion_of(:role, :in=>[:owner, :potential_owner, :excluded_owner], :not_in=>:foo) }
    it { should validate_inclusion_of(:role, :in=>[:creator, :observer, :supervisor]) }
  end

  describe 'existing' do
    subject { Stakeholder.make }

    it { should be_readonly }
    it('should not allow person/task/role duplicate')       { subject.clone.should have(1).error_on(:role) }
  end

end
