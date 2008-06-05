require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/helper'


describe Stakeholder do

  describe 'person' do
    it 'should be part of stakeholder' do
      Task.create! defaults(:creator=>person('creator'))
      Stakeholder.last.person.should == person('creator')
    end

    it 'should be required' do
      Task.create! defaults
      Stakeholder.create(:task=>Task.last, :role=>'admin').should have(1).error_on(:person)
    end
  end


  describe 'task' do
    it 'should be part of stakeholder' do
      Task.create! defaults(:creator=>person('creator'))
      Stakeholder.last.task.should == Task.last
    end

    it 'should be required' do
      lambda { Stakeholder.create(:person=>person('creator'), :role=>'admin') }.should raise_error(ActiveRecord::StatementInvalid)
    end
  end


  describe 'role' do
    it 'should be part of stakeholder' do
      Task.create! defaults(:creator=>person('creator'))
      Stakeholder.last.role.should == 'creator'
    end

    it 'should be required' do
      Task.create! defaults
      Stakeholder.create(:person=>person('me'), :task=>Task.last).should have(1).error_on(:role)
    end

    it 'should be any valid role names' do
      Task.create! defaults
      Stakeholder::ALL_ROLES.each do |role|
        Stakeholder.create(:person=>person('me'), :task=>Task.last, :role=>role).should have(:no).errors
      end
    end

    it 'should not allow unknown role names' do
      Task.create! defaults
      ['foo', 'bar'].each do |role|
        Stakeholder.create(:person=>person('me'), :task=>Task.last, :role=>role).should have(1).error_on(:role)
      end
    end
  end


  it 'should be unique combination of task person and role' do
    Task.create! defaults
    Stakeholder.create(:person=>person('me'), :task=>Task.last, :role=>'admin').should have(:no).errors
    Stakeholder.create(:person=>person('me'), :task=>Task.last, :role=>'observer').should have(:no).errors
    Stakeholder.create(:person=>person('me'), :task=>Task.last, :role=>'admin').should have(1).errors_on(:role)
  end

  it 'should be deleted when task destroyed' do
    Task.create! defaults(:creator=>person('creator'))
    lambda { Task.last.destroy }.should change(Stakeholder, :count).to(0)
  end

  it 'should be deleted when person destroyed' do
    Task.create! defaults(:creator=>person('creator'))
    lambda { person('creator').destroy }.should change(Stakeholder, :count).to(0)
  end

  it 'should be read only' do
    Task.create! defaults(:creator=>person('creator'))
    lambda { Stakeholder.last.update_attributes! :role=>'owner' }.should raise_error(ActiveRecord::ReadOnlyRecord)
  end
end


describe Task do

  shared_examples_for 'singular role' do
    it 'should not be required' do
      Task.create(defaults.except(@role)).should have(:no).errors
    end

    it 'should not exist unless specified' do
      Task.create! defaults.except(@role)
      Task.last.send(@role).should be_nil
    end

    it 'should accept person at task creation' do
      Task.create(defaults.merge(@role=>person('foo'))).should have(:no).errors
    end

    it 'should return person when loading task' do
      Task.create! defaults.merge(@role=>person('foo'))
      Task.last.send(@role).should eql(person('foo'))
    end

    it 'should identify person in role' do
      Task.create! defaults.merge(@role=>person('foo'))
      Task.last.send("#{@role}?", person('foo')).should be_true
      Task.last.send("#{@role}?", person('bar')).should be_false
    end
  end

  describe 'creator' do
    before { @role = :creator }
    it_should_behave_like 'singular role'

    it 'should not allow changing creator' do
      Task.create! defaults.merge(:creator=>person('creator'))
      lambda { Task.last.update_attributes :creator=>person('other') }.should_not change { Task.last.creator }
      lambda { Task.last.update_attributes :creator=>nil }.should_not change { Task.last.creator }
    end

    it 'should not allow setting creator on existing task' do
      Task.create! defaults
      lambda { Task.last.update_attributes :creator=>person('creator') }.should_not change { Task.last.creator }
    end

    it 'should report error when changing creator' do
      task = Task.create! defaults
      task.update_attributes :creator=>person('creator')
      task.should have(1).error_on(:creator)
    end

    it 'should allow changing creator on reserved task only' do
      Task.create! defaults.merge(:status=>'reserved', :creator=>person('creator'))
      lambda { Task.last.update_attributes :creator=>person('other') }.should change { Task.last.creator }
    end
  end

  describe 'owner' do
    before { @role = :owner }
    it_should_behave_like 'singular role'

    it 'should allow changing owner on existing task' do
      Task.create! defaults.merge(:owner=>person('owner'))
      Task.last.update_attributes! :owner=>person('other')
      Task.last.owner.should == person('other')
    end

    it 'should only store one owner association for task' do
      Task.create! defaults.merge(:owner=>person('owner'))
      Task.last.update_attributes! :owner=>person('other')
      Stakeholder.find(:all, :conditions=>{:task_id=>Task.last.id}).size.should == 1
    end

    it 'should allow setting owner to nil' do
      Task.create! defaults.merge(:owner=>person('owner'))
      Task.last.update_attributes! :owner=>nil
      Task.last.owner.should be_nil
    end

    it 'should treat empty string as nil' do
      Task.create! defaults.merge(:owner=>person('owner'))
      Task.last.update_attributes! :owner=>''
      Task.last.owner.should be_nil
    end

    it 'should not allow owner if listed in excluded owners' do
      Task.create! defaults.merge(:excluded_owners=>person('excluded'))
      lambda { Task.last.update_attributes! :owner=>person('excluded') }.should raise_error
      Task.last.owner.should be_nil
    end

    it 'should be potential owner if task created with one potential owner' do
      Task.create! defaults.merge(:potential_owners=>person('foo'))
      Task.last.owner.should == person('foo')
    end

    it 'should not be potential owner if task created with more than one' do
      Task.create! defaults.merge(:potential_owners=>people('foo', 'bar'))
      Task.last.owner.should be_nil
    end

    it 'should not be potential owner if task updated to have no owner' do
      Task.create! defaults.merge(:potential_owners=>person('foo'))
      Task.last.update_attributes! :owner=>person('bar')
      Task.last.update_attributes! :owner=>nil
      Task.last.owner.should be(nil)
    end
  end


  shared_examples_for 'plural role' do
    before do
      @people = person('foo'), person('bar'), person('baz')
    end

    it 'should not be required' do
      Task.create(defaults.except(@role)).should have(:no).errors
    end

    it 'should not exist unless specified' do
      Task.create! defaults.except(@role)
      Task.last.send(@role).should be_empty
    end

    it 'should accept list of people at task creation' do
      Task.create(defaults.merge(@role=>@people)).should have(:no).errors
    end

    it 'should list of people when loading task' do
      Task.create! defaults.merge(@role=>@people)
      Task.last.send(@role).should == @people
    end

    it 'should accept single person' do
      Task.create! defaults.merge(@role=>person('foo'))
      Task.last.send(@role).should == [person('foo')]
    end

    it 'should accept empty list' do
      Task.create(defaults.merge(@role=>[]))
      Task.last.send(@role).should be_empty
    end

    it 'should accept empty list and discard all stakeholders' do
      Task.create! defaults.merge(@role=>@people)
      Task.last.update_attributes! @role=>[]
      Task.last.send(@role).should be_empty
    end

    it 'should accept nil and treat it as empty list' do
      Task.create! defaults.merge(@role=>@people)
      Task.last.update_attributes! @role=>nil
      Task.last.send(@role).should be_empty
    end

    it 'should allow adding stakeholders' do
      Task.create! defaults.merge(@role=>person('foo'))
      Task.last.update_attributes! @role=>[person('foo'), person('bar')]
      Task.last.send(@role).should == [person('foo'), person('bar')]
    end

    it 'should add each person only once' do
      Task.create! defaults.merge(@role=>([person('foo')] *3))
      Task.last.send(@role).size.should == 1
    end

    it 'should allow removing stakeholders' do
      Task.create! defaults.merge(@role=>[person('foo'), person('bar')])
      Task.last.update_attributes! @role=>person('bar')
      Task.last.send(@role).should == [person('bar')]
    end

    it 'should identify person in role' do
      Task.create! defaults.merge(@role=>person('foo'))
      Task.last.send("#{@role.to_s.singularize}?", person('foo')).should be_true
      Task.last.send("#{@role.to_s.singularize}?", person('bar')).should be_false
    end
  end

  describe 'potential_owners' do
    before { @role = :potential_owners }
    it_should_behave_like 'plural role'

    it 'should not allow excluded owners' do
      mixed_up = { :potential_owners=>[person('foo'), person('bar')],
                   :excluded_owners=>[person('bar'), person('baz')] }
      Task.create(defaults.merge(mixed_up)).should have(1).error_on(:potential_owners)
    end
  end

  describe 'excluded_owners' do
    before { @role = :excluded_owners }
    it_should_behave_like 'plural role'
  end

  describe 'observers' do
    before { @role = :observers }
    it_should_behave_like 'plural role'
  end

  describe 'admins' do
    before { @role = :admins }
    it_should_behave_like 'plural role'
  end

end
