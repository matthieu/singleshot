require File.dirname(__FILE__) + '/../spec_helper'

describe Activity do
  include Specs::Tasks

  before :all do
    @person = person('person')
    @task = Task.create(default_task)
  end

  describe 'person' do
    it 'should be stored' do
      Activity.create! :person=>@person, :action=>'created', :task=>@task
      Activity.last.person.should == @person
    end

    it 'should be optional' do
      lambda { Activity.create! :action=>'created', :task=>@task }.should_not raise_error
      Activity.last.person.should be_nil
    end
  end

  describe 'task' do
    it 'should be stored' do
      Activity.create! :person=>@person, :action=>'created', :task=>@task
      Activity.last.task.should == @task
    end

    it 'should be required' do
      Activity.create(:person=>@person, :action=>'created').should have(1).error_on(:task)
    end
  end

  describe 'action' do
    it 'should be stored' do
      Activity.create! :person=>@person, :action=>'created', :task=>@task
      Activity.last.action.should == 'created'
    end

    it 'should be required' do
      Activity.create(:person=>@person, :task=>@task).should have(1).error_on(:action)
    end
  end

  it 'should have created_at timestamp' do
    Activity.create!(:person=>@person, :action=>'created', :task=>@task).created_at.should be_close(Time.now, 2)
  end
  
  it 'should allow creation but not modification' do
    Activity.create! :person=>@person, :action=>'created', :task=>@task
    lambda { Activity.last.update_attributes! :action=>'updated' }.should raise_error(ActiveRecord::ReadOnlyRecord)
  end

  describe 'for_dates' do
    it 'should return activities in date range' do
      # 0 days (today) already created for activity associated with task creation.
      now = Activity.last.created_at
      activities = (1..3).each do |i|
        last = Activity.create! :person=>@person, :action=>'created', :task=>@task
        Activity.update_all(['created_at=?', now - i.day], ['id=?', last.id])
      end
      Activity.for_dates(now.to_date - 2.days..now.to_date).count == 1
      Activity.for_dates(now.to_date - 2.days..now.to_date).each do |activity|
        activity.created_at.should >= now - 2.days and activity.created_at <= now.end_of_date
      end
    end
  end

  describe 'for_stakeholder' do
    before { Activity.delete_all }

    it 'should return activities for tasks associated with person' do
      for role in Stakeholder::ALL_ROLES - ['excluded_owners']
        Task.create! default_task.merge(Task::ACCESSOR_FROM_ROLE[role]=>@person)
      end
      Activity.for_stakeholder(@person).map(&:task).uniq.size.should == Stakeholder::ALL_ROLES.size - 1
    end

    it 'should not return activities for excluded owners' do
      Task.create! default_task.merge(:excluded_owners=>@person)
      Activity.for_stakeholder(@person).should be_empty
    end

    it 'should not return activities for other stakeholders' do
      Task.create! default_task.merge(:status=>'reserved', :potential_owners=>person('other'))
      Activity.for_stakeholder(@person).should be_empty
    end

    it 'should return activities for tasks with visible status' do
      for status in Task::STATUSES - ['reserved']
        task_with_status status, :potential_owners=>@person
      end
      Activity.for_stakeholder(@person).map(&:task).uniq.size.should == Task::STATUSES.size - 1
    end

    it 'should not return activities for reserved tasks' do
      Task.create! default_task.merge(:status=>'reserved', :potential_owners=>@person)
      Activity.for_stakeholder(@person).should be_empty
    end

    it 'should return all activities for a visible task' do
      Task.create! default_task.merge(:creator=>person('creator'))
      Task.last.update_attributes(:owner=>person('owner'))
      Activity.for_stakeholder(person('creator')).should == Activity.for_stakeholder(person('owner'))
      Activity.for_stakeholder(person('creator')).map(&:action).should include('created', 'is owner of')
      Activity.for_stakeholder(person('owner')).map(&:person).should include(person('creator'), person('owner'))
    end

  end

end
