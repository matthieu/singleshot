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


describe Stakeholder do

  subject { Stakeholder.new :person=>person('john.smith'), :task=>new_task, :role=>:owner }

  it { should belong_to(:person, Person) }
  it { should validate_presence_of(:person) }

  it { should belong_to(:task, Task) }
  it('should require task association') { lambda { subject.update_attributes!(:task=>nil) }.should raise_error(ActiveRecord::StatementInvalid) }

  it { should have_attribute(:role, :string, :null=>false) }
  it { should validate_presence_of(:role) }
  it { should validate_inclusion_of(:role, :in=>[:owner, :potential_owner, :excluded_owner], :not_in=>:foo) }
  it { should validate_inclusion_of(:role, :in=>[:creator, :observer, :supervisor]) }

  it('should not allow person/task/role duplicate')         { subject.clone.save! ; subject.should have(1).error_on(:role) }
  it('should be readonly')                                  { subject.save! ; subject.reload.should be_readonly }

end
