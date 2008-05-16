require File.dirname(__FILE__) + '/../spec_helper'


describe Stakeholder do
  include Specs::Tasks

  before :all do
    @person = person('person')
    @task = Task.create(default_task)
  end

  it 'should have person' do
    Stakeholder.create(:task=>@task, :role=>'admin').should have(1).error_on(:person)
  end

  it 'should have task' do
    lambda { Stakeholder.create(:person=>@person, :role=>'admin') }.should raise_error(ActiveRecord::StatementInvalid)
  end

  it 'should have role' do
    Stakeholder.create(:person=>@person, :task=>@task).should have(1).error_on(:role)
  end

  it 'should have supported role' do
    Stakeholder::ROLES.each do |role|
      Stakeholder.create(:person=>@person, :task=>@task, :role=>role).should have(:no).errors
    end
  end

  it 'should not have unsupported role' do
    ['foo', 'bar'].each do |role|
      Stakeholder.create(:person=>@person, :task=>@task, :role=>role).should have(1).error_on(:role)
    end
  end

  it 'should be unique combination of task person and role' do
    Stakeholder.create(:person=>@person, :task=>@task, :role=>'admin').should have(:no).errors
    Stakeholder.create(:person=>@person, :task=>@task, :role=>'observer').should have(:no).errors
    Stakeholder.create(:person=>@person, :task=>@task, :role=>'admin').should have(1).errors_on(:role)
  end
end


shared_examples_for 'singular role' do
  include Specs::Tasks

  it 'should not be required' do
    Task.create(default_task.except(@role)).should have(:no).errors
  end

  it 'should not exist unless specified' do
    Task.create default_task.except(@role)
    Task.first.send(@role).should be_nil
  end

  it 'should accept person at task creation' do
    Task.create(default_task.merge(@role=>person('foo'))).should have(:no).errors
  end

  it 'should return person when loading task' do
    Task.create default_task.merge(@role=>person('foo'))
    Task.first.send(@role).should eql(person('foo'))
  end

  it 'should identify person in role' do
    Task.create default_task.merge(@role=>person('foo'))
    Task.first.send("#{@role}?", person('foo')).should be_true
    Task.first.send("#{@role}?", person('bar')).should be_false
  end
end


describe Task, 'creator' do
  before { @role = :creator }
  it_should_behave_like 'singular role'

  it 'should not allow changing creator' do
    Task.create default_task.merge(:creator=>person('creator'))
    Task.first.update_attributes :creator=>person('other')
    Task.first.creator.should == person('creator')
  end

  it 'should not allow setting creator on existing task' do
    Task.create default_task
    Task.first.update_attributes :creator=>person('creator')
    Task.first.creator.should be_nil
  end

end


describe Task, 'owner' do
  before { @role = :owner }
  it_should_behave_like 'singular role'

  it 'should allow changing owner on existing task' do
    Task.create default_task.merge(:owner=>person('owner'))
    Task.first.update_attributes! :owner=>person('other')
    Task.first.owner.should == person('other')
  end

  it 'should only store one owner association for task' do
    Task.create default_task.merge(:owner=>person('owner'))
    Task.first.update_attributes! :owner=>person('other')
    Stakeholder.find(:all, :conditions=>{:task_id=>Task.first.id}).size.should == 1
  end

  it 'should allow setting owner to nil' do
    Task.create default_task.merge(:owner=>person('owner'))
    Task.first.update_attributes! :owner=>nil
    Task.first.owner.should be_nil
  end

  it 'should not allow owner if listed in excluded owners' do
    Task.create default_task.merge(:excluded_owners=>person('excluded'))
    lambda { Task.first.update_attributes! :owner=>person('excluded') }.should raise_error
    Task.first.owner.should be_nil
  end

  it 'should be potential owner if task created with one potential owner' do
    Task.create default_task.merge(:potential_owners=>person('foo'))
    Task.first.owner.should == person('foo')
  end

  it 'should not be potential owner if task created with more than one' do
    Task.create default_task.merge(:potential_owners=>people('foo', 'bar'))
    Task.first.owner.should be_nil
  end

  it 'should not be potential owner if task updated to have no owner' do
    Task.create default_task.merge(:potential_owners=>person('foo'))
    Task.first.update_attributes! :owner=>person('bar')
    Task.first.update_attributes! :owner=>nil
    Task.first.owner.should be(nil)
  end
end


shared_examples_for 'plural role' do
  include Specs::Tasks

  before do
    @people = person('foo'), person('bar'), person('baz')
  end

  it 'should not be required' do
    Task.create(default_task.except(@role)).should have(:no).errors
  end

  it 'should not exist unless specified' do
    Task.create default_task.except(@role)
    Task.first.send(@role).should be_empty
  end

  it 'should accept list of people at task creation' do
    Task.create(default_task.merge(@role=>@people)).should have(:no).errors
  end

  it 'should list of people when loading task' do
    Task.create default_task.merge(@role=>@people)
    Task.first.send(@role).should == @people
  end

  it 'should accept single person' do
    Task.create default_task.merge(@role=>person('foo'))
    Task.first.send(@role).should == [person('foo')]
  end

  it 'should accept empty list' do
    Task.create(default_task.merge(@role=>[]))
    Task.first.send(@role).should be_empty
  end

  it 'should accept empty list and discard all stakeholders' do
    Task.create default_task.merge(@role=>@people)
    Task.first.update_attributes! @role=>[]
    Task.first.send(@role).should be_empty
  end

  it 'should accept nil and treat it as empty list' do
    Task.create default_task.merge(@role=>@people)
    Task.first.update_attributes! @role=>nil
    Task.first.send(@role).should be_empty
  end

  it 'should allow adding stakeholders' do
    Task.create default_task.merge(@role=>person('foo'))
    Task.first.update_attributes! @role=>[person('foo'), person('bar')]
    Task.first.send(@role).should == [person('foo'), person('bar')]
  end

  it 'should add each person only once' do
    Task.create default_task.merge(@role=>([person('foo')] *3))
    Task.first.send(@role).size.should == 1
  end

  it 'should allow removing stakeholders' do
    Task.create default_task.merge(@role=>[person('foo'), person('bar')])
    Task.first.update_attributes! @role=>person('bar')
    Task.first.send(@role).should == [person('bar')]
  end

  it 'should identify person in role' do
    Task.create default_task.merge(@role=>person('foo'))
    Task.first.send("#{@role.to_s.singularize}?", person('foo')).should be_true
    Task.first.send("#{@role.to_s.singularize}?", person('bar')).should be_false
  end
end


describe Task, 'potential_owners' do
  before { @role = :potential_owners }
  it_should_behave_like 'plural role'

  it 'should not allow excluded owners' do
    mixed_up = { :potential_owners=>[person('foo'), person('bar')],
                 :excluded_owners=>[person('bar'), person('baz')] }
    Task.create(default_task.merge(mixed_up)).should have(1).error_on(:potential_owners)
  end
end


describe Task, 'excluded_owners' do
  before { @role = :excluded_owners }
  it_should_behave_like 'plural role'
end


describe Task, 'observers' do
  before { @role = :observers }
  it_should_behave_like 'plural role'
end


describe Task, 'admins' do
  before { @role = :admins }
  it_should_behave_like 'plural role'
end
