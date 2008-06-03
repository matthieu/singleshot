require File.dirname(__FILE__) + '/../spec_helper'

describe Activity do
  include Specs::Tasks

  describe 'person' do
    it 'should be part of activity' do
      Task.create! default_task(:creator=>person('person'))
      Activity.last.person.should == person('person')
    end

    it 'should be optional' do
      lambda { Task.create! default_task }.should_not raise_error
      Activity.last.person.should be_nil
    end
  end

  describe 'task' do
    it 'should be part of activity' do
      Task.create! default_task
      Activity.last.task.should == Task.last
    end

    it 'should be required' do
      Activity.create(:person=>person('person'), :action=>'created').should have(1).error_on(:task)
    end
  end

  describe 'action' do
    it 'should be part of activity' do
      Task.create! default_task
      Activity.last.action.should == 'created'
    end

    it 'should be required' do
      Task.create! default_task
      Activity.create(:person=>person('person'), :task=>Task.last).should have(1).error_on(:action)
    end
  end

  it 'should have created_at timestamp' do
    Task.create! default_task
    Activity.last.created_at.should be_close(Time.now, 2)
  end
  
  it 'should allow creation but not modification' do
    Task.create! default_task
    lambda { Activity.last.update_attributes! :action=>'updated' }.should raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it 'should delete when destroying task' do
    Task.create! default_task
    lambda { Task.last.destroy }.should change(Activity, :count).to(0)
  end

  it 'should delete when destroying person' do
    Task.create! default_task(:creator=>person('creator'))
    lambda { person('creator').destroy }.should change(Activity, :count).to(0)
  end

  describe 'for_dates' do
    it 'should return activities in date range' do
      now = Time.zone.now
      activities = (0..3).each do |i|
        Task.create! default_task(:creator=>person('creator'))
        Activity.update_all ['created_at=?', now - i.day], ['id=?', Activity.last.id]
      end
      min, max = Activity.minimum(:created_at) + 1.day, Activity.maximum(:created_at)
      Activity.for_dates(min.to_date..max.to_date).count == 1
      Activity.for_dates(min.to_date..max.to_date).each do |activity|
        activity.created_at.should be_between(min, max)
      end
    end
  end

  describe 'for_stakeholder' do

    it 'should return activities for tasks associated with person' do
      for role in Stakeholder::ALL_ROLES - ['excluded_owners']
        Task.create! default_task.merge(Task::ACCESSOR_FROM_ROLE[role]=>person('person'))
      end
      Activity.for_stakeholder(person('person')).map(&:task).uniq.size.should == Stakeholder::ALL_ROLES.size - 1
    end

    it 'should not return activities for excluded owners' do
      Task.create! default_task.merge(:excluded_owners=>person('person'))
      Activity.for_stakeholder(person('person')).should be_empty
    end

    it 'should not return activities for other stakeholders' do
      Task.create! default_task.merge(:status=>'reserved', :potential_owners=>person('other'))
      Activity.for_stakeholder(person('person')).should be_empty
    end

    it 'should return activities for tasks with visible status' do
      for status in Task::STATUSES - ['reserved']
        task_with_status status, :potential_owners=>person('person')
      end
      Activity.for_stakeholder(person('person')).map(&:task).uniq.size.should == Task::STATUSES.size - 1
    end

    it 'should not return activities for reserved tasks' do
      Task.create! default_task.merge(:status=>'reserved', :potential_owners=>person('person'))
      Activity.for_stakeholder(person('person')).should be_empty
    end

    it 'should return all activities for a visible task' do
      Task.create! default_task.merge(:creator=>person('creator'))
      Task.last.update_attributes! :owner=>person('owner')
      Activity.for_stakeholder(person('creator')).should == Activity.for_stakeholder(person('owner'))
      Activity.for_stakeholder(person('creator')).map(&:action).should include('created', 'is owner of')
      Activity.for_stakeholder(person('owner')).map(&:person).should include(person('creator'), person('owner'))
    end

    it 'should return activities from most recent to last' do
      Task.create! default_task.merge(:creator=>person('creator'))
      Activity.update_all ['created_at=?', Time.zone.now - 5.seconds]
      Task.last.update_attributes! :owner=>person('owner')
      activities = Activity.for_stakeholder(person('creator'))
      activities.first.created_at.should > activities.last.created_at
    end

  end

end
