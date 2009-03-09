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
# Table name: tasks
#
#  id                 :integer         not null, primary key
#  status             :string(255)     not null
#  title              :string(255)     not null
#  description        :string(255)
#  language           :string(5)
#  priority           :integer(1)      not null
#  due_on             :date
#  start_on           :date
#  cancellation       :string(255)
#  perform_integrated :boolean
#  view_integrated    :boolean
#  perform_url        :string(255)
#  view_url           :string(255)
#  data               :text            not null
#  hooks              :string(255)
#  access_key         :string(32)      not null
#  version            :integer         not null
#  created_at         :datetime
#  updated_at         :datetime
#
describe Task do

  subject { Task.make }

  # -- Descriptive --

  it { should have_attribute(:title) }
  it { should have_db_column(:title, :type=>:string) }
  it { should allow_mass_assignment_of(:title) }
  it { should_not validate_uniqueness_of(:title) }
  it { should validate_presence_of(:title) }

  it { should have_attribute(:description) }
  it { should have_db_column(:description, :type=>:string) }
  it { should allow_mass_assignment_of(:description) }
  it { should_not validate_uniqueness_of(:description) }
  it { should_not validate_presence_of(:description) }

  it { should have_attribute(:language) }
  it { should have_db_column(:language, :type=>:string, :limit=>5) }
  it { should allow_mass_assignment_of(:language) }
  it { should_not validate_presence_of(:language) }


  # -- Urgency --

  it { should have_attribute(:priority) }
  it { should have_db_column(:priority, :type=>:integer, :limit=>1) }
  it { should allow_mass_assignment_of(:priority) }
  it('should default to priority 3')          { subject.priority.should == 3 }
  it { should validate_inclusion_of(:priority, :in=>1..5) }

  it { should have_attribute(:due_on) }
  it { should have_db_column(:due_on, :type=>:date) }
  it { should allow_mass_assignment_of(:due_on) }

  it { should have_attribute(:start_on) }
  it { should have_db_column(:start_on, :type=>:date) }
  it { should allow_mass_assignment_of(:start_on) }


  # -- Stakeholders --
  describe 'stakeholders' do

    it { should have_many(:stakeholders, :include=>:person, :dependent=>:delete_all) }
    it { should allow_mass_assignment_of(:stakeholders) }
    it { should allow_mass_assignment_of(:owner) }

    describe '#in_role' do
      before { @foo, @bar, @baz = Person.named('foo', 'bar', 'baz') }
      it('should return all people in a given role') { subject.associate(:find=>[@foo, @bar], :miss=>@baz).in_role(:find).should == [@foo, @bar] }
    end

    describe '#in_role?' do
      subject { Task.make.associate(:find=>Person.named('foo', 'bar'), :miss=>Person.named('baz')) }
      it('should identify all people in a given role') { [subject.in_role?(:find, 'foo'), subject.in_role?(:find, 'bar'),
                                                          subject.in_role?(:miss, 'foo')].should == [true, true, false] }
      it('should return nil if no identity given')     { subject.in_role?(:find, nil).should be_false }
    end

    describe 'creator' do
      subject { Person.creator }

      it('should not have more than one creator')     { lambda { Task.make.associate! :creator=>[subject, Person.owner] }.
                                                        should raise_error(ActiveRecord::RecordInvalid) }
      it { should_not able_to_claim_task }
      it { should_not able_to_delegate_task }
      it { should_not able_to_suspend_task }
      it { should_not able_to_resume_task }
      it { should_not able_to_cancel_task }
      it { should_not able_to_complete_task }
      it { should_not able_to_change_task }
    end

    describe '#owner' do
      subject { Task.make }

      it('should be nil if no person in this role') { subject.owner.should be_nil }
      it('should return person in role owner')      { subject.associate(:owner=>Person.owner).owner.should == Person.owner }
      it('should accept new owner')                 { lambda { subject.owner = Person.owner }.should change(subject, :owner).to(Person.owner) and
                                                      lambda { subject.owner = Person.other }.should change(subject, :owner).to(Person.other) }
    end

    describe 'owner' do
      subject { Person.owner }

      it('should not have more than one owner')       { lambda { Task.make.associate! :owner=>[subject, Person.owner] }.
                                                        should raise_error(ActiveRecord::RecordInvalid) }
      it('should default to single potential owner')  { Task.make.tap { |t| t.associate!(:potential_owner=>subject) }.owner.should == subject }
      it { should able_to_claim_task }
      it { should able_to_delegate_task }
      it { should_not able_to_suspend_task }
      it { should_not able_to_resume_task }
      it { should_not able_to_cancel_task }
      it { should able_to_complete_task }
      it { should able_to_change_task(:data) }
    end

    describe 'past owner' do
      subject { Person.past_owner }

      it('should be previous owner of task')   { subject.should == Task.make.in_role(:past_owner).first }
      it { should able_to_claim_task }
      it { should_not able_to_delegate_task }
      it { should_not able_to_suspend_task }
      it { should_not able_to_resume_task }
      it { should_not able_to_cancel_task }
      it { should_not able_to_complete_task }
      it { should_not able_to_change_task }
    end

    describe 'potential owner' do
      subject { Person.potential }

      it { should able_to_claim_task }
      it { should_not able_to_delegate_task }
      it { should_not able_to_suspend_task }
      it { should_not able_to_resume_task }
      it { should_not able_to_cancel_task }
      it { should_not able_to_complete_task }
      it { should_not able_to_change_task }
    end

    describe 'excluded owner' do
      subject { Person.excluded }

      it { should_not able_to_claim_task }
      it { should_not able_to_delegate_task }
      it { should_not able_to_suspend_task }
      it { should_not able_to_resume_task }
      it { should_not able_to_cancel_task }
      it { should_not able_to_complete_task }
      it { should_not able_to_change_task }
    end

    describe 'supervisor' do
      subject { Person.supervisor }

      it { should able_to_claim_task }
      it { should able_to_delegate_task }
      it { should able_to_suspend_task }
      it { should able_to_resume_task }
      it { should able_to_cancel_task }
      it { should_not able_to_complete_task }
      it { should able_to_change_task(:all) }
    end

    describe 'observer' do
      subject { Person.observer }

      it { should_not able_to_claim_task }
      it { should_not able_to_delegate_task }
      it { should_not able_to_suspend_task }
      it { should_not able_to_resume_task }
      it { should_not able_to_cancel_task }
      it { should_not able_to_complete_task }
      it { should_not able_to_change_task }
    end

    describe 'other' do
      subject { Person.other }

      it('should not be able to see task')  { lambda { subject.tasks.find(Task.make) }.should raise_error(ActiveRecord::RecordNotFound) }
    end

  end

  # -- Status --
  describe 'status' do

    it { should have_attribute(:status) }
    it { should have_db_column(:status, :type=>:string) }
    it { should allow_mass_assignment_of(:status) }
    it('should not allow random values') { subject.status = :random ; subject.should have(1).error_on(:status) }

    describe 'available' do
      subject { Task.make }

      it('should be the initial status for new tasks')            { Task.new(:status=>:active).status.should == :available }
      it { should change_status_to(:active, "with new owner")     { subject.update_attributes! :owner=>Person.owner } }
      it { should_not change_status("on its own accord")          { subject.save! } }
      it { should honor_cancellation_policy }
      it { should_not change_status_to(:completed)                { Person.supervisor.tasks.find(subject).update_attributes :owner=>Person.owner, :status=>:completed } }
      it { should offer_potential_owner_to_claim }
      it { should offer_supervisor_to_suspend }
      it { should_not offer_supervisor_to_resume }
      it { should offer_supervisor_to_cancel }
      it { should_not offer_owner_to_complete }
      it { should offer_supervisor_to_change }
    end

    describe 'active' do
      subject { Task.make_active }

      it('should be status for owned tasks')                  { subject.status.should == :active }
      it { should change_status_to(:available, "if no owner") { Person.owner.tasks.find(subject).update_attributes :owner=>nil } }
      it { should_not change_status("with owner change")      { Person.owner.tasks.find(subject).update_attributes :owner=>Person.potential } }
      it { should change_status_to(:suspended, "if suspended by supervisor")  { Person.supervisor.tasks.find(subject).update_attributes :status=>:suspended } }
      it { should_not change_status("unless suspended by supervisor")         { Person.owner.tasks.find(subject).update_attributes :status=>:suspended } }
      it { should honor_cancellation_policy }
      it { should change_status_to(:completed, "when completed by owner")     { Person.owner.tasks.find(subject).update_attributes :status=>:completed } }
      it { should_not change_status_to(:completed, "unless by owner")         { Person.supervisor.tasks.find(subject).update_attributes :status=>:completed } }
      it { should_not offer_potential_owner_to_claim }
      it { should_not offer_supervisor_to_suspend }
      it { should_not offer_supervisor_to_resume }
      it { should offer_supervisor_to_cancel }
      it { should offer_owner_to_complete }
      it { should offer_supervisor_to_change }
    end

    describe 'suspended' do
      subject { Task.make_suspended }

      it { should change_status_to(:available, "if resumed and no owner")  { Person.supervisor.tasks.find(subject).update_attributes! :status=>:active } }
      it { should change_status_to(:active, "if resumed with owner")       { subject.associate! :owner=>Person.owner ; Person.supervisor.tasks.find(subject).update_attributes! :status=>:available } }
      it { should_not change_status("unless resumed by supervisor")        { Person.owner.tasks.find(subject).update_attributes :status=>:active } }
      it { should honor_cancellation_policy }
      it { should_not change_status_to(:completed)                         { Person.owner.tasks.find(subject).update_attributes :owner=>Person.owner, :status=>:completed } }
      it { should_not offer_potential_owner_to_claim }
      it { should_not offer_supervisor_to_suspend }
      it { should offer_supervisor_to_resume }
      it { should offer_supervisor_to_cancel }
      it { should_not offer_owner_to_complete }
      it { should offer_supervisor_to_change }
    end

    describe 'completed' do
      subject { Task.make_completed }

      it { should be_readonly }
      it { should_not offer_potential_owner_to_claim }
      it { should_not offer_supervisor_to_suspend }
      it { should_not offer_supervisor_to_resume }
      it { should_not offer_supervisor_to_cancel }
      it { should_not offer_owner_to_complete }
      it { should_not offer_supervisor_to_change }
    end

    describe 'cancelled' do
      subject { Task.make_cancelled }

      it { should be_readonly }
      it { should_not offer_potential_owner_to_claim }
      it { should_not offer_supervisor_to_suspend }
      it { should_not offer_supervisor_to_resume }
      it { should_not offer_supervisor_to_cancel }
      it { should_not offer_owner_to_complete }
      it { should_not offer_supervisor_to_change }
    end

  end


  describe 'newly created' do
    subject { Person.creator.tasks.create!(:title=>'foo') }

    it { should be_available }
    it('should have creator') { subject.in_role(:creator).should == [Person.creator] }
    it('should have supervisor') { subject.in_role(:supervisor).should == [Person.creator] }
    it('should not have owner') { subject.owner.should be_nil }
    it { should log_activity(Person.creator, :created) }
  end

  describe 'created and delegated' do
    subject { Person.creator.tasks.create!(:title=>'foo', :owner=>Person.owner) }

    it { should be_active }
    it('should have creator') { subject.in_role(:creator).should == [Person.creator] }
    it('should have owner') { subject.owner.should == Person.owner }
    it { should log_activity(Person.creator, :created) }
    it { should log_activity(Person.owner, :claimed) }
  end

  describe 'owner claiming' do
    subject { Task.make }
    before do
      Person.owner.tasks.find(subject).update_attributes! :owner=>Person.owner
      subject.reload
    end

    it { should be_active }
    it('should have owner') { subject.owner.should == Person.owner }
    it { should log_activity(Person.owner, :claimed) }
  end

  describe 'owner delegating' do
    subject { Task.make_active }
    before do
      Person.owner.tasks.find(subject).update_attributes! :owner=>Person.potential
      subject.reload
    end

    it { should be_active }
    it('should have new owner') { subject.owner.should == Person.potential }
    it { should log_activity(Person.owner, :delegated) }
    it { should log_activity(Person.potential, :claimed) }
  end

  describe 'supervisor delegating' do
    subject { Task.make }
    before do
      Person.supervisor.tasks.find(subject).update_attributes! :owner=>Person.potential
      subject.reload
    end

    it { should be_active }
    it('should have new owner') { subject.owner.should == Person.potential }
    it { should log_activity(Person.supervisor, :delegated) }
    it { should log_activity(Person.potential, :claimed) }
  end

  describe 'owner releasing' do
    subject { Task.make_active }
    before do
      Person.owner.tasks.find(subject).update_attributes! :owner=>nil
      subject.reload
    end

    it { should be_available }
    it('should have no owner') { subject.owner.should be_nil }
    it { should log_activity(Person.owner, :released) }
  end

  describe 'supervisor suspending' do
    subject { Task.make_active }
    before do
      Person.supervisor.tasks.find(subject).update_attributes! :status=>:suspended
      subject.reload
    end

    it { should be_suspended }
    it('should retain owner') { subject.owner.should == Person.owner }
    it { should log_activity(Person.supervisor, :suspended) }
  end

  describe 'supervisor resuming' do
    subject { Task.make_active }
    before do
      Person.supervisor.tasks.find(subject).update_attributes! :status=>:suspended
      Person.supervisor.tasks.find(subject).update_attributes! :status=>:active
      subject.reload
    end

    it { should be_active }
    it('should retain owner') { subject.owner.should == Person.owner }
    it { should log_activity(Person.supervisor, :resumed) }
  end

  describe 'supervisor cancelling' do
    subject { Task.make_active }
    before do
      Person.supervisor.tasks.find(subject).update_attributes! :status=>:cancelled
      subject.reload
    end

    it { should be_cancelled }
    it('should retain owner') { subject.owner.should == Person.owner }
    it { should log_activity(Person.supervisor, :cancelled) }
  end

  describe 'owner completing' do
    subject { Task.make_active }
    before do
      Person.owner.tasks.find(subject).update_attributes! :status=>:completed
      subject.reload
    end

    it { should be_completed }
    it('should retain owner') { subject.owner.should == Person.owner }
    it { should log_activity(Person.owner, :completed) }
  end

  describe 'supervisor modifying' do
    subject { Task.make_active }
    before do
      Person.supervisor.tasks.find(subject).update_attributes! :title=>subject.title.upcase
      subject.reload
    end

    it { should log_activity(Person.supervisor, :modified) }
  end


  # -- Activity --
  
  it { should have_many(:activities, :include=>[:task, :person], :dependent=>:delete_all, :order=>'activities.created_at desc') }
  it { should_not allow_mass_assignment_of(:activities) }


  # -- Data --

  it { should have_attribute(:data) }
  it { should have_db_column(:data, :type=>:text) }
  it { should allow_mass_assignment_of(:data) }
  it('should have empty hash as default data')  { subject.data.should == {} }
  it('should allowing assigning nil to data')   { subject.update_attributes :data => nil; subject.data.should == {} }
  it('should validate data is a hash')          { lambda { Person.supervisor.tasks.find(subject).update_attributes! :data=>'string' }.
                                                  should raise_error(ActiveRecord::RecordInvalid) }
  it('should store and retrieve data')          { Person.supervisor.tasks.find(subject).update_attributes!(:data=>{ 'foo'=>'bar'})
                                                  subject.reload.data.should == { 'foo'=>'bar' } }


  # -- Access key --

  it { should have_attribute(:access_key) }
  it { should have_db_column(:access_key, :type=>:string, :limit=>32) }
  it { should_not allow_mass_assignment_of(:access_key) }
  it('should create hexdigest access key')                { subject.access_key.should =~ /^[0-9a-f]{32}$/ }
  it('should give each task unique access key')           { [Task.make, Task.make, Task.make].map(&:access_key).uniq.size.should be(3) }

  it { should have_attribute(:version) }
  it { should have_db_column(:version, :type=>:integer) }
  it('should have locking column version') { subject.class.locking_enabled? && subject.class.locking_column == 'version' }
  it { should have_attribute(:created_at) }
  it { should have_db_column(:created_at, :type=>:datetime) }
  it { should have_attribute(:updated_at) }
  it { should have_db_column(:updated_at, :type=>:datetime) }


  # -- Query scopes --

  it { should have_named_scope(:completed, :conditions=>"tasks.status = 'completed'", :order=>'tasks.updated_at desc') }
  it { should have_named_scope(:cancelled, :conditions=>"tasks.status = 'cancelled'", :order=>'tasks.updated_at desc') }


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
      Person.supervisor.tasks.find(given).update_attributes :status=>:cancelled
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
      fail unless subject.can_claim?(task) == (subject.tasks.find(task).update_attributes(:owner=>subject) rescue false)
      task.reload.owner == subject
    end
  end

  # Expecting that subject is able to delegate task to one of its potential owners.
  def able_to_delegate_task
    simple_matcher "be offered/able to delegate task" do |given|
      task = Task.make_active
      fail unless subject.can_delegate?(task, Person.potential) == subject.tasks.find(task).update_attributes(:owner=>Person.potential)
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
      fail unless subject.can_suspend?(task) == subject.tasks.find(task).update_attributes(:status=>:suspended)
      task.reload.status == :suspended
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
      fail unless subject.can_resume?(task) == subject.tasks.find(task).update_attributes(:status=>:available)
      task.reload.status == :available
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
      fail unless subject.can_cancel?(task) == subject.tasks.find(task).update_attributes(:status=>:cancelled)
      task.reload.status == :cancelled
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
      fail unless subject.can_complete?(task) == subject.tasks.find(task).update_attributes(:status=>:completed)
      task.reload.status == :completed
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
      all = { :title=>'new title', :priority=>5, :due_on=>Date.tomorrow, :data=>{ 'foo'=>'bar' },
              :stakeholders=>[Stakeholder.new(:person=>Person.observer, :role=>:observer),
                              Stakeholder.new(:person=>Person.supervisor, :role=>:supervisor)] }
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
  #   it { should log_activity(Person.owner, :completed) { Person.owner.tasks(id).update_attributes :status=>:completed } }
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
