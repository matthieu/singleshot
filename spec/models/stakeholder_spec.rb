# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with this
# work for additional information regarding copyright ownership.  The ASF
# licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.


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
