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


describe Activity do

  describe 'person' do
    it 'should be part of activity' do
      Task.create! defaults(:creator=>person('person'))
      Activity.last.person.should == person('person')
    end

    it 'should be optional' do
      lambda { Task.create! defaults }.should_not raise_error
      Activity.last.person.should be_nil
    end
  end

  describe 'task' do
    it 'should be part of activity' do
      Task.create! defaults
      Activity.last.task.should == Task.last
    end

    it 'should be required' do
      Activity.create(:person=>person('person'), :name=>'created').should have(1).error_on(:task)
    end
  end

  describe 'name' do
    it 'should be part of activity' do
      Task.create! defaults
      Activity.last.name.should == 'created'
    end

    it 'should be required' do
      Task.create! defaults
      Activity.create(:person=>person('person'), :task=>Task.last).should have(1).error_on(:name)
    end
  end

  it 'should have created_at timestamp' do
    Task.create! defaults
    Activity.last.created_at.should be_close(Time.now, 2)
  end
  
  it 'should be read only' do
    Task.create! defaults
    lambda { Activity.last.update_attributes! :name=>'updated' }.should raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it 'should be removed when destroying task' do
    Task.create! defaults
    lambda { Task.last.destroy }.should change(Activity, :count).to(0)
  end

  it 'should be removed when destroying person' do
    Task.create! defaults(:creator=>person('creator'))
    lambda { person('creator').destroy }.should change(Activity, :count).to(0)
  end


  describe 'for_dates' do
    it 'should accept time and find all activities since that day' do
      Activity.for_dates(3.days.ago).proxy_options[:conditions][:created_at].should ==
        (3.days.ago.beginning_of_day..Time.current.end_of_day)
    end
    
    it 'should accept date and find all activities since that day' do
      Activity.for_dates(Date.current - 3.days).proxy_options[:conditions][:created_at].should ==
        (3.days.ago.beginning_of_day..Time.current.end_of_day)
    end

    it 'should accept time range and find all activities in these dates' do
      Activity.for_dates(3.days.ago..1.day.ago).proxy_options[:conditions][:created_at].should ==
        (3.days.ago.beginning_of_day..1.day.ago.end_of_day)
    end

    it 'should accept date range and find all activities in these dates' do
      Activity.for_dates(Date.current - 3.days..Date.current - 1.day).proxy_options[:conditions][:created_at].should ==
        (3.days.ago.beginning_of_day..1.day.ago.end_of_day)
    end
  end


  describe 'for_stakeholder' do
    it 'should return activities from all tasks associated with stakeholder' do
      Task.create! defaults(:creator=>person('person'))
      Task.create! defaults(:owner=>person('person'))
      Task.create! defaults(:observers=>person('person'))
      Activity.for_stakeholder(person('person')).map(&:task).uniq.size.should == 3
    end

    it 'should not return activities for excluded owner' do
      Task.create! defaults(:excluded_owners=>person('person'))
      Activity.for_stakeholder(person('person')).should be_empty
    end

    it 'should not return activities not relevant to stakeholder' do
      Task.create! defaults(:creator=>person('creator'))
      Task.create! defaults(:owner=>person('owner'))
      Activity.for_stakeholder(person('creator')).first.task.should == Task.first
      Activity.for_stakeholder(person('owner')).last.task.should == Task.last
    end

    it 'should order activities from most recent to last' do
      Task.create! defaults(:creator=>person('person'))
      Activity.update_all ['created_at=?', Time.zone.now - 5.seconds]
      Task.create! defaults(:owner=>person('person'))
      activities = Activity.for_stakeholder(person('person'))
      activities.first.created_at.should > activities.last.created_at
    end

    it 'should not return the same activity twice' do
      Task.create! defaults(:creator=>person('person'), :observers=>person('person'))
      Activity.for_stakeholder(person('person')).size.should == 1
    end

    it 'should not eager load dependencies' do
      Activity.for_stakeholder(person('person')).proxy_options[:include].should be_nil
    end
  end


  describe 'recently_added' do
    it 'should return recently added activities' do
      Activity.recently_added.proxy_options[:order].downcase.split.should == ['created_at', 'desc']
    end
    
  end


end
