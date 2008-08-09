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


require File.dirname(__FILE__) + '/../spec_helper'


describe Person do
  
  describe 'activities' do
    before do
      Task.create! defaults(:creator=>person('creator'), :owner=>person(:owner))
      Task.create! defaults(:owner=>person(:owner))
    end
  
    it 'should return all activities associated with that person' do
      person(:creator).activities.map { |a| [a.name, a.task, a.person] }.
        should include(['created', Task.first, person(:creator)])
      person(:owner).activities.map { |a| [a.name, a.task, a.person] }.
        should include(['owner', Task.first, person(:owner)], ['owner', Task.last, person(:owner)])
    end
    
    it 'should return only activities associated with that person' do
      person(:creator).activities.map(&:person).uniq.should == [person(:creator)]
      person(:owner).activities.map(&:person).uniq.should == [person(:owner)]
    end
    
    it 'should allow eager loading with dependents' do
      person(:owner).activities.with_dependents.proxy_options[:include].should include(:task, :person)
    end
    
  end
  
end