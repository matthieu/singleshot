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
require File.dirname(__FILE__) + '/base_spec'


# == Schema Information
# Schema version: 20090421005807
#
# Table name: tasks
#
#  id           :integer(4)      not null, primary key
#  status       :string(255)     not null
#  title        :string(255)     not null
#  description  :string(255)
#  language     :string(5)
#  priority     :integer(1)      not null
#  due_on       :date
#  start_on     :date
#  cancellation :string(255)
#  data         :text            default(""), not null
#  hooks        :string(255)
#  access_key   :string(32)      not null
#  version      :integer(4)      not null
#  created_at   :datetime
#  updated_at   :datetime
#  type         :string(255)     not null
#
describe Task do
  subject { Task.make }
  it_should_behave_like 'Base'

  # -- Urgency --

  should_have_attribute :priority
  should_have_column :priority, :type=>:integer, :limit=>1
  it('should default to priority 2')          { subject.priority.should == 2 }
  should_validate_inclusion_of :priority, :in=>1..3

  should_have_attribute :due_on
  should_have_column :due_on, :type=>:date
  should_have_attribute :start_on
  should_have_column :start_on, :type=>:date
  should_allow_mass_assignment_of :priority, :due_on, :start_on
  should_not_validate_presence_of :priority, :due_on, :start_on


  # -- Stakeholders --
  describe 'stakeholders' do

    should_have_many :stakeholders, :include=>:person, :dependent=>:delete_all
    should_not_allow_mass_assignment_of :stakeholders
    should_allow_mass_assignment_of :creator, :owner
    should_have_readonly_attribute :creator

    describe '#in_role' do
      before { @foo, @bar, @baz = Person.named('foo', 'bar', 'baz') }
      it('should return all people in a given role') { subject.associate('supervisors'=>[@foo, @bar], 'observers'=>@baz).in_role('supervisors').should == [@foo, @bar] }
    end

    describe '#in_role?' do
      subject { Task.make.associate('supervisors'=>Person.named('foo', 'bar'), 'observers'=>Person.named('baz')) }
      it('should identify all people in a given role') { [subject.in_role?('supervisors', 'foo'), subject.in_role?('find', 'bar'),
                                                          subject.in_role?('observers', 'foo')].should == [true, true, false] }
      it('should return nil if no identity given')     { subject.in_role?('supervisors', nil).should be_false }
    end

    describe '#creator' do
      subject { Task.make :creator=>nil }

      it('should be nil if no person in this role') { subject.creator.should be_nil }
      it('should return person in role creator')    { subject.associate('creator'=>Person.creator).creator.should == Person.creator }
      it('should accept new creator')               { lambda { Person.supervisor.tasks.find(subject).update_attributes! :creator=>Person.creator }.
                                                        should change { Task.find(subject).creator }.to(Person.creator) }
    end

    describe 'creator' do
      subject { Person.creator }

      it('should not have more than one creator')     { lambda { Task.make.associate! 'creator'=>[subject, Person.owner] }.
                                                        should raise_error(ActiveRecord::RecordInvalid) }
      should_not_able_to_claim_task
      should_not_able_to_delegate_task
      should_not_able_to_suspend_task
      should_not_able_to_resume_task
      should_not_able_to_cancel_task
      should_not_able_to_complete_task 
      should_not_able_to_change_task
    end

    describe '#owner' do
      subject { Task.make }

      it('should be nil if no person in this role') { subject.owner.should be_nil }
      it('should return person in role owner')      { subject.associate('owner'=>Person.owner).owner.should == Person.owner }
      it('should accept new owner')                 { lambda { subject.owner = Person.owner }.should change(subject, :owner).to(Person.owner) }
    end

    describe 'owner' do
      subject { Person.owner }

      it('should not have more than one owner')       { lambda { Task.make.associate! 'owner'=>[subject, Person.owner] }.
                                                        should raise_error(ActiveRecord::RecordInvalid) }
      it('should default to single potential owner')  { Task.make.tap { |t| t.associate!('potential_owner'=>subject) }.owner.should == subject }
      should_able_to_claim_task
      should_able_to_delegate_task
      should_not_able_to_suspend_task
      should_not_able_to_resume_task
      should_not_able_to_cancel_task
      should_able_to_complete_task
      should_able_to_change_task :data
    end

    describe 'past owner' do
      subject { Person.past_owner }

      it('should be previous owner of task')   { subject.should == Task.make.past_owners.first }
      should_able_to_claim_task
      should_not_able_to_delegate_task
      should_not_able_to_suspend_task
      should_not_able_to_resume_task
      should_not_able_to_cancel_task
      should_not_able_to_complete_task
      should_not_able_to_change_task
    end

    describe 'potential owner' do
      subject { Person.potential }

      should_able_to_claim_task
      should_not_able_to_delegate_task
      should_not_able_to_suspend_task
      should_not_able_to_resume_task
      should_not_able_to_cancel_task
      should_not_able_to_complete_task
      should_not_able_to_change_task
    end

    describe 'excluded owner' do
      subject { Person.excluded }

      should_not_able_to_claim_task
      should_not_able_to_delegate_task
      should_not_able_to_suspend_task
      should_not_able_to_resume_task
      should_not_able_to_cancel_task
      should_not_able_to_complete_task
      should_not_able_to_change_task
    end

    describe 'supervisor' do
      subject { Person.supervisor }

      should_able_to_claim_task
      should_able_to_delegate_task
      should_able_to_suspend_task
      should_able_to_resume_task
      should_able_to_cancel_task
      should_not_able_to_complete_task
      should_able_to_change_task :all
    end

    describe 'observer' do
      subject { Person.observer }

      should_not_able_to_claim_task
      should_not_able_to_delegate_task
      should_not_able_to_suspend_task
      should_not_able_to_resume_task
      should_not_able_to_cancel_task
      should_not_able_to_complete_task
      should_not_able_to_change_task 
    end

    describe 'other' do
      subject { Person.other }

      it('should not be able to see task')  { lambda { subject.tasks.find(Task.make) }.should raise_error(ActiveRecord::RecordNotFound) }
    end

  end


  # -- Status --
  describe 'status' do

    should_have_attribute :status
    should_have_column :status, :type=>:string
    should_allow_mass_assignment_of :status
    it('should not allow random values') { subject.status = :random ; subject.should have(1).error_on(:status) }

    describe 'available' do
      subject { Task.make }

      it('should be the initial status for new tasks')            { Task.new(:status=>'active').status.should == 'available' }
      it { should change_status_to('active', "with new owner")    { Person.owner.tasks.find(subject).update_attributes! :owner=>Person.owner } }
      it { should_not change_status("on its own accord")          { subject.save! } }
      it { should honor_cancellation_policy }
      it { should_not change_status_to('completed')               { Person.supervisor.tasks.find(subject).update_attributes :owner=>Person.owner, :status=>'completed' } }
      should_offer_potential_owner_to_claim
      should_offer_supervisor_to_suspend
      should_not_offer_supervisor_to_resume
      should_offer_supervisor_to_cancel
      should_not_offer_owner_to_complete
      should_offer_supervisor_to_change
    end

    describe 'active' do
      subject { Task.make_active }

      it('should be status for owned tasks')                    { subject.status.should == 'active' }
      it { should change_status_to('available', "if no owner")  { Person.owner.tasks.find(subject).update_attributes :owner=>nil } }
      it { should_not change_status("with owner change")        { Person.owner.tasks.find(subject).update_attributes :owner=>Person.potential } }
      it { should change_status_to('suspended', "if suspended by supervisor") { Person.supervisor.tasks.find(subject).update_attributes :status=>'suspended' } }
      it { should_not change_status("unless suspended by supervisor")         { Person.owner.tasks.find(subject).update_attributes :status=>'suspended' } }
      it { should honor_cancellation_policy }
      it { should change_status_to('completed', "when completed by owner")     { Person.owner.tasks.find(subject).update_attributes :status=>'completed' } }
      it { should_not change_status_to('completed', "unless by owner")         { Person.supervisor.tasks.find(subject).update_attributes :status=>'completed' } }
      should_not_offer_potential_owner_to_claim
      should_not_offer_supervisor_to_suspend
      should_not_offer_supervisor_to_resume
      should_offer_supervisor_to_cancel
      should_offer_owner_to_complete
      should_offer_supervisor_to_change
    end

    describe 'suspended' do
      subject { Task.make_suspended }

      it { should change_status_to('available', "if resumed and no owner")  { Person.supervisor.tasks.find(subject).update_attributes! :status=>'active' } }
      it { should change_status_to('active', "if resumed with owner")       { subject.associate! 'owner'=>Person.owner ; Person.supervisor.tasks.find(subject).update_attributes! :status=>'available' } }
      it { should_not change_status("unless resumed by supervisor")        { Person.owner.tasks.find(subject).update_attributes :status=>'active' } }
      it { should honor_cancellation_policy }
      it { should_not change_status_to('completed')                         { Person.owner.tasks.find(subject).update_attributes :owner=>Person.owner, :status=>'completed' } }
      should_not_offer_potential_owner_to_claim
      should_not_offer_supervisor_to_suspend
      should_offer_supervisor_to_resume
      should_offer_supervisor_to_cancel
      should_not_offer_owner_to_complete
      should_offer_supervisor_to_change
    end

    describe 'completed' do
      subject { Task.make_completed }

      should_be_readonly
      should_not_offer_potential_owner_to_claim
      should_not_offer_supervisor_to_suspend
      should_not_offer_supervisor_to_resume
      should_not_offer_supervisor_to_cancel
      should_not_offer_owner_to_complete
      should_not_offer_supervisor_to_change
    end

    describe 'cancelled' do
      subject { Task.make_cancelled }

      should_be_readonly
      should_not_offer_potential_owner_to_claim
      should_not_offer_supervisor_to_suspend
      should_not_offer_supervisor_to_resume
      should_not_offer_supervisor_to_cancel
      should_not_offer_owner_to_complete
      should_not_offer_supervisor_to_change
    end

  end

  # -- Activity --
  
  should_have_many :activities, :include=>[:task, :person], :dependent=>:delete_all, :order=>'activities.created_at desc'
  should_not_allow_mass_assignment_of :activities

  describe 'newly created' do
    subject { Person.creator.tasks.create!(:title=>'foo') }

    should_be_available
    it('should have creator')                     { subject.creator.should == Person.creator }
    it('should have creator as supervisor')       { subject.supervisors.should == [Person.creator] }
    it('should have no owner')                    { subject.owner.should be_nil }
    should_log_activity Person.creator, 'created'
  end

  describe 'created and delegated' do
    subject { Person.creator.tasks.create!(:title=>'foo', :owner=>Person.owner) }

    should_be_active
    it('should have creator') { subject.creator.should == Person.creator }
    it('should have owner') { subject.owner.should == Person.owner }
    should_log_activity Person.creator, 'created'
    should_log_activity Person.owner, 'claimed'
  end

  describe 'owner claiming' do
    subject { Task.make }
    before do
      Person.owner.tasks.find(subject).update_attributes! :owner=>Person.owner
      subject.reload
    end

    should_be_active
    it('should have owner') { subject.owner.should == Person.owner }
    should_log_activity Person.owner, 'claimed'
  end

  describe 'owner delegating' do
    subject { Task.make_active }
    before do
      Person.owner.tasks.find(subject).update_attributes! :owner=>Person.potential
      subject.reload
    end

    should_be_active
    it('should have new owner') { subject.owner.should == Person.potential }
    should_log_activity Person.owner, 'delegated'
    should_log_activity Person.potential, 'claimed'
  end

  describe 'supervisor delegating' do
    subject { Task.make }
    before do
      Person.supervisor.tasks.find(subject).update_attributes! :owner=>Person.potential
      subject.reload
    end

    should_be_active
    it('should have new owner') { subject.owner.should == Person.potential }
    should_log_activity Person.supervisor, 'delegated'
    should_log_activity Person.potential, 'claimed'
  end

  describe 'owner releasing' do
    subject { Task.make_active }
    before do
      Person.owner.tasks.find(subject).update_attributes! :owner=>nil
      subject.reload
    end

    should_be_available
    it('should have no owner') { subject.owner.should be_nil }
    should_log_activity Person.owner, 'released'
  end

  describe 'supervisor suspending' do
    subject { Task.make_active }
    before do
      Person.supervisor.tasks.find(subject).update_attributes! :status=>'suspended'
      subject.reload
    end

    should_be_suspended
    it('should retain owner') { subject.owner.should == Person.owner }
    should_log_activity Person.supervisor, 'suspended'
  end

  describe 'supervisor resuming' do
    subject { Task.make_active }
    before do
      Person.supervisor.tasks.find(subject).update_attributes! :status=>'suspended'
      Person.supervisor.tasks.find(subject).update_attributes! :status=>'active'
      subject.reload
    end

    should_be_active
    it('should retain owner') { subject.owner.should == Person.owner }
    should_log_activity Person.supervisor, 'resumed'
  end

  describe 'supervisor cancelling' do
    subject { Task.make_active }
    before do
      Person.supervisor.tasks.find(subject).update_attributes! :status=>'cancelled'
      subject.reload
    end

    should_be_cancelled
    it('should retain owner') { subject.owner.should == Person.owner }
    should_log_activity Person.supervisor, 'cancelled'
  end

  describe 'owner completing' do
    subject { Task.make_active }
    before do
      Person.owner.tasks.find(subject).update_attributes! :status=>'completed'
      subject.reload
    end

    should_be_completed
    it('should retain owner') { subject.owner.should == Person.owner }
    should_log_activity Person.owner, 'completed'
  end

  describe 'supervisor modifying' do
    subject { Task.make_active }
    before do
      Person.supervisor.tasks.find(subject).update_attributes! :title=>subject.title.upcase
      subject.reload
    end

    should_log_activity Person.supervisor, 'modified'
  end


  # -- Access key --

  should_have_attribute :access_key
  should_have_column :access_key, :type=>:string, :limit=>32
  should_not_allow_mass_assignment_of :access_key
  it('should create hexdigest access key')                { subject.access_key.should =~ /^[0-9a-f]{32}$/ }
  it('should give each task unique access key')           { [Task.make, Task.make, Task.make].map(&:access_key).uniq.size.should be(3) }

  should_have_attribute :version
  should_have_column :version, :type=>:integer
  it('should have locking column version') { subject.class.locking_enabled? && subject.class.locking_column == 'version' }
  should_have_attribute :created_at
  should_have_attribute :updated_at
  should_have_column :created_at, :updated_at, :type=>:datetime


  # -- Query scopes --

  should_have_named_scope 'completed', :conditions=>"tasks.status = 'completed'", :order=>'tasks.updated_at desc'
  should_have_named_scope 'cancelled', :conditions=>"tasks.status = 'cancelled'", :order=>'tasks.updated_at desc'


  # Expecting the subject to change status after executing the block. Uses the reason argument
  # as part of the description. Most often used in the negative. For example:
  #   it { should_not change_status("when changing title") { subject.title = "modified" } }
  def change_status(reason = nil, &block)
    simple_matcher "change status #{reason}" do |given, matcher|
      before = given.status
      if block.call
        after = given.reload.status
        matcher.failure_message = "expected status to change from #{before}, but did not change"
        matcher.negative_failure_message = "expected status not to change from #{before}, but changed to #{after}"
        before != after
      end
    end
  end

  # Expecting the subject to change status to the specific status after executing the block.
  # Uses the reason argument as part of the description. For example:
  #   it { should change_status_to('cancelled', "if cancelled") { subject.cancel! } }
  def change_status_to(status, reason = nil)
    simple_matcher "change status to #{status} #{reason}" do |given, matcher|
      matcher.failure_message = "expected status to change to #{status}, but already #{status}"
      matcher.negative_failure_message = "expected status not to change to #{status}, but already #{status}"
      before = given.status
      unless (before = given.status) == status
        yield
        after = given.reload.status
        matcher.failure_message = before == after ? "expected status to change to #{status}, but did not change" :
                                                    "expected status to change to #{status}, but changed to #{after}"
        matcher.negative_failure_message = "expected message not to change to #{status}, but changed to #{status}"
        after == status
      end
    end
  end

  # Expecting task in current status to allow cancellation only on behalf of supervisor. For example:
  #  it { should honor_cancellation_policy }
  def honor_cancellation_policy
    simple_matcher "honor cancellation policy" do |given, matcher|
      matcher.failure_message = "expected status to change to cancelled, but did not change"
      Person.supervisor.tasks.find(given).update_attributes :status=>'cancelled'
    end
  end

  # Expecting that potential own can claim subject.
  def offer_potential_owner_to_claim
    simple_matcher("offer potential owner to claim task") { |given| Person.potential.can_claim?(subject) }
  end

  # Expecting that subject is offered to and can claim task.
  def able_to_claim_task
    simple_matcher "be offered/able to claim task" do |given|
      task = Task.make
      allowed = subject.can_claim?(task)
      changed = subject.tasks.find(task).update_attributes(:owner=>subject) rescue false
      fail unless allowed == changed 
      task.reload.owner == subject
    end
  end

  # Expecting that subject is able to delegate task to one of its potential owners.
  def able_to_delegate_task
    simple_matcher "be offered/able to delegate task" do |given|
      task = Task.make_active
      allowed = subject.can_delegate?(task, Person.potential)
      changed = subject.tasks.find(task).update_attributes(:owner=>Person.potential) rescue false
      fail unless allowed == changed
      task.reload.owner == Person.potential
    end
  end

  # Expecting that supervisor own can suspend subject.
  def offer_supervisor_to_suspend
    simple_matcher("offer supervisor to suspend task") { |given| Person.supervisor.can_suspend?(subject) }
  end

  # Expecting that subject is offered to and can suspend task.
  def able_to_suspend_task
    simple_matcher "be offered/able to suspend task" do |given|
      task = Task.make
      fail unless subject.can_suspend?(task) == subject.tasks.find(task).update_attributes(:status=>'suspended')
      task.reload.status == 'suspended'
    end
  end

  # Expecting that supervisor own can suspend subject.
  def offer_supervisor_to_resume
    simple_matcher("offer supervisor to resume task") { |given| Person.supervisor.can_resume?(subject) }
  end

  # Expecting that subject is offered to and can resume suspended task.
  def able_to_resume_task
    simple_matcher "be offered/able to resume task" do |given|
      task = Task.make_suspended
      fail unless subject.can_resume?(task) == subject.tasks.find(task).update_attributes(:status=>'available')
      task.reload.status == 'available'
    end
  end

  # Expecting that supervisor own can cancel subject.
  def offer_supervisor_to_cancel
    simple_matcher("offer supervisor to cancel task") { |given| Person.supervisor.can_cancel?(subject) }
  end

  # Expecting that subject is offered to and can cancel task.
  def able_to_cancel_task
    simple_matcher "be offered/able to cancel task" do |given, matcher|
      task = Task.make
      fail unless subject.can_cancel?(task) == subject.tasks.find(task).update_attributes(:status=>'cancelled')
      task.reload.status == 'cancelled'
    end
  end

  # Expecting that owner own can complete subject.
  def offer_owner_to_complete
    simple_matcher("offer owner to complete task") { |given| Person.owner.can_complete?(subject) }
  end

  # Expecting that subject is offered to and can complete active task.
  def able_to_complete_task
    simple_matcher "be offered/able to complete task" do |given, matcher|
      task = Task.make_active
      fail unless subject.can_complete?(task) == subject.tasks.find(task).update_attributes(:status=>'completed')
      task.reload.status == 'completed'
    end
  end

  # Expecting that supervisor own can change subject.
  def offer_supervisor_to_change
    simple_matcher("offer supervisor to change task") { |given| Person.supervisor.can_change?(subject) }
  end

  # Expecting that subject can change a particular set of attributes:
  # - nil/:any -- Can change attribute. This is used in the negative form.
  # - :all -- Can change all attributes.
  # - symbols -- Can change specific attributes.
  #
  # For example:
  #   it { should_not able_to_change_task }
  #   it { should able_to_change_task(:data) }
  def able_to_change_task(*attrs)
    simple_matcher "be able to change task" do |given|
      all = { :title=>'new title', :priority=>3, :due_on=>Date.tomorrow, :data=>{ 'foo'=>'bar' },
              :observers=>[Person.observer.to_param] }
      changed = all.select { |attr, value| subject.tasks.find(Task.make_active).update_attributes(attr=>value) rescue false }.map(&:first)
      case attrs.first
      when nil, :any
        fail if subject.can_change?(Task.make_active)
        !changed.empty?
      when :all
        fail unless subject.can_change?(Task.make_active)
        changed == all.keys
      else
        fail if subject.can_change?(Task.make_active)
        changed == attrs
      end
    end
  end


  # Expecting a new activity to show up after yielding to block, matching task (subject), person and name.
  # For example:
  #   it { should log_activity(Person.owner, 'completed') { Person.owner.tasks(id).update_attributes :status=>'completed' } }
  def log_activity(person, name)
    simple_matcher "log activity '#{person.to_param} #{name}'" do |given, matcher|
      if block_given?
        Activity.delete_all
        yield
      end
      activities = Activity.all
      matcher.failure_message = "expecting activity \"#{person.to_param} #{name} #{given.title}\" but got #{activities.empty? ? 'nothing' : activities.map(&:name).to_sentence.inspect} instead"
      activities.any? { |activity| activity.task == given && activity.person == person && activity.name == name }
    end
  end

end
