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

  it { should have_attribute(:title, :string, :null=>false) }
  it { should allow_mass_assigning_of(:title) }
  it { should_not validate_uniquness_of(:title) }
  it { should validate_presence_of(:title) }

  it { should have_attribute(:description, :string, :null=>true) }
  it { should allow_mass_assigning_of(:description) }
  it { should_not validate_uniquness_of(:description) }
  it { should_not validate_presence_of(:description) }

  it { should have_attribute(:language, :string, :null=>true, :limit=>5) }
  it { should allow_mass_assigning_of(:language) }
  it { should_not validate_presence_of(:language) }


  # -- Urgency --

  def allow_priority(value) # expecting priority to validate
    simple_matcher("allow priority #{value}") { |given| given.priority = value ; given.valid? || given.errors.on(:priority).nil? }
  end

  it { should have_attribute(:priority, :integer, :null=>false, :limit=>1) }
  it { should allow_mass_assigning_of(:priority) }
  it('should default to priority 3')          { subject.priority.should == 3 }
  it { should allow_priority(1) }
  it { should allow_priority(5) }
  it { should_not allow_priority(0) }
  it { should_not allow_priority(6) }

  it { should have_attribute(:due_on, :date, :null=>true) }
  it { should allow_mass_assigning_of(:due_on) }

  it { should have_attribute(:start_on, :date, :null=>true) }
  it { should allow_mass_assigning_of(:start_on) }


  # -- Stakeholders --
  describe 'stakeholders' do

    it { should have_many(:stakeholders, Stakeholder, :include=>:person, :dependent=>:delete_all) }
    it { should allow_mass_assigning_of(:stakeholders) }
    it { should allow_mass_assigning_of(:owner) }

    describe '#associate' do
      before { @foo, @bar = Person.named('foo', 'bar') }
      it('should associate person with role') { subject.associate(:role=>@foo).in_role(:role).should == [@foo] }
      it('should associate people with role') { subject.associate(:role=>[@foo, @bar]).in_role(:role).should == [@foo, @bar] }
      it('should associate no one with role') { subject.associate(:role=>nil).in_role(:role).should be_empty }
    end

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
=begin

      it { should allow_delegation('owner', 'potential') } # Can delegate to another potential owner, or noone (release),
      it { should_not allow_delegation('owner', 'other') } # but can't delegate to random person.
      it { should_not allow_delegation('owner', 'excluded') }
      it { should allow_delegation('owner', nil) }
      it { should_not allow_delegation('other', 'other') }  # Random person can't delegate to themselves, neither can potential owners.
      it { should allow_delegation('potential', 'potential') }
      it { should allow_delegation('supervisor', 'other') } # Supervisor can delegate to anyone, except excluded owners.
      it { should_not allow_delegation('supervisor', 'excluded') }
=end
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
      it { should able_to_change_task }
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

      it { should_not able_to_claim_task }
      it { should_not able_to_delegate_task }
      it { should_not able_to_suspend_task }
      it { should_not able_to_resume_task }
      it { should_not able_to_cancel_task }
      it { should_not able_to_complete_task }
      it { should_not able_to_change_task }
    end

  end

  # -- Status --
  describe 'status' do

    it { should have_attribute(:status, :string, :null=>false) }
    it { should allow_mass_assigning_of(:status) }
    it('should not allow random values') { subject.status = :random ; subject.should have(1).error_on(:status) }

    describe 'available' do
      subject { Task.make }

      it('should be the initial status for new tasks')            { Task.new(:status=>:active).status.should == :available }
      it { should change_status_to(:active, "with new owner")     { subject.update_attributes! :owner=>Person.owner } }
      it { should_not change_status("on its own accord")          { subject.save! } }
      it { should honor_cancellation_policy }
      it { should_not change_status_to(:completed)                { Person.supervisor.update_task subject, :owner=>Person.owner, :status=>:completed } }
      it { should offer_potential_owner_to_claim }
      it { should offer_supervisor_to_suspend }
      it { should_not offer_supervisor_to_resume }
      it { should offer_supervisor_to_cancel }
      it { should_not offer_owner_to_complete }
    end

    describe 'active' do
      subject { Task.make_active }

      it('should be status for owned tasks')                  { subject.status.should == :active }
      it { should change_status_to(:available, "if no owner") { Person.owner.update_task subject, :owner=>nil } }
      it { should_not change_status("with owner change")      { Person.owner.update_task subject, :owner=>Person.potential } }
      it { should change_status_to(:suspended, "if suspended by supervisor")  { Person.supervisor.update_task subject, :status=>:suspended } }
      it { should_not change_status("unless suspended by supervisor")         { Person.owner.update_task subject, :status=>:suspended } }
      it { should honor_cancellation_policy }
      it { should change_status_to(:completed, "when completed by owner")     { Person.owner.update_task subject, :status=>:completed } }
      it { should_not change_status_to(:completed, "unless by owner")         { Person.supervisor.update_task subject, :status=>:completed } }
      it { should_not offer_potential_owner_to_claim }
      it { should_not offer_supervisor_to_suspend }
      it { should_not offer_supervisor_to_resume }
      it { should offer_supervisor_to_cancel }
      it { should offer_owner_to_complete }
    end

    describe 'suspended' do
      subject { Task.make_suspended }

      it { should change_status_to(:available, "if resumed and no owner")  { Person.supervisor.update_task! subject, :status=>:active } }
      it { should change_status_to(:active, "if resumed with owner")       { subject.owner = Person.owner ; Person.supervisor.update_task! subject, :status=>'available' } }
      it { should_not change_status("unless resumed by supervisor")        { Person.owner.update_task subject, :status=>:active } }
      it { should honor_cancellation_policy }
      it { should_not change_status_to(:completed)                         { Person.owner.update_task subject, :owner=>Person.owner, :status=>:completed } }
      it { should_not offer_potential_owner_to_claim }
      it { should_not offer_supervisor_to_suspend }
      it { should offer_supervisor_to_resume }
      it { should offer_supervisor_to_cancel }
      it { should_not offer_owner_to_complete }
    end

    describe 'completed' do
      subject { Task.make_completed }

      it { should be_in_terminal_state }
      it { should be_readonly }
      it { should_not offer_potential_owner_to_claim }
      it { should_not offer_supervisor_to_suspend }
      it { should_not offer_supervisor_to_resume }
      it { should_not offer_supervisor_to_cancel }
      it { should_not offer_owner_to_complete }
    end

    describe 'cancelled' do
      subject { Task.make_cancelled }

      it { should be_in_terminal_state }
      it { should be_readonly }
      it { should_not offer_potential_owner_to_claim }
      it { should_not offer_supervisor_to_suspend }
      it { should_not offer_supervisor_to_resume }
      it { should_not offer_supervisor_to_cancel }
      it { should_not offer_owner_to_complete }
    end

  end


  # -- Data --

  it { should have_attribute(:data, :text, :null=>false) }
  it { should allow_mass_assigning_of(:data) }
  it('should have empty hash as default data')  { subject.data.should == {} }
  it('should allowing assigning nil to data')   { subject.update_attributes :data => nil; subject.data.should == {} }
  it('should validate data is a hash')          { lambda { subject.update_attributes :data=>'string' }.should raise_error }
  it('should store and retrieve data')          { subject.update_attributes(:data=>{ 'foo'=>'bar'})
                                                  subject.reload.data.should == { 'foo'=>'bar' } }


  # -- Access key --

  it { should have_attribute(:access_key, :string, :null=>false, :limit=>32) }
  it { should_not allow_mass_assigning_of(:access_key) }
  it('should create hexdigest access key')                { subject.access_key.should look_like_hexdigest(32) }
  it('should give each task unique access key')           { [Task.make, Task.make, Task.make].map(&:access_key).uniq.size.should be(3) }

  it { should have_locking_column(:version) }
  it { should have_created_at_timestamp }
  it { should have_updated_at_timestamp }


  # Expecting the subject to change status after executing the block. Uses the reason argument
  # as part of the description. Most often used in the negative. For example:
  #   it { should_not change_status("when changing title") { subject.title = "modified" } }
  def change_status(reason, &block)
    simple_matcher "change status #{reason}" do |given, matcher|
      before = given.status
      if block.call
        after = given.status
        matcher.failure_message = "expected status to change from #{before}, but did not change"
        matcher.negative_failure_message = "expected status not to change from #{before}, but changed to #{after}"
        before != after
      end
    end
  end

  # Expecting the subject to change status to the specific status after executing the block.
  # Uses the reason argument as part of the description. For example:
  #   it { should change_status_to('cancelled', "if cancelled") { subject.cancel! } }
  def change_status_to(status, reason = nil, &block)
    simple_matcher "change status to #{status} #{reason}" do |given, matcher|
      matcher.failure_message = "expected status to change to #{status}, but already #{status}"
      matcher.negative_failure_message = "expected status not to change to #{status}, but already #{status}"
      before = given.status
      unless (before = given.status) == status
        if block.call
          after = given.status
          matcher.failure_message = before == after ? "expected status to change to #{status}, but did not change" :
                                                      "expected status to change to #{status}, but changed to #{after}"
          matcher.negative_failure_message = "expected message not to change to #{status}, but changed to #{status}"
          after == status
        end
      end
    end
  end

  # Expecting the current status to be a terminal state. Clones the subject and tries to change the
  # status, expecting no change to go through. For example:
  #   before { subject.completed! }
  #   it { should be_in_terminal_state }
  def be_in_terminal_state
    simple_matcher "be terminal state" do |given, matcher|
      check = Task::STATUSES - [given.status]
      failed = check.select { |status| given.clone.update_attributes(:status=>status) }
      matcher.failure_message = "expected status to be terminal, but managed to change to #{failed.to_sentence}"
      failed.empty?
    end
  end

  # Expecting task in current status to allow cancellation only on behalf of supervisor. For example:
  #  it { should honor_cancellation_policy }
  def honor_cancellation_policy
    simple_matcher "honor cancellation policy" do |given, matcher|
      matcher.failure_message = "expected status to change to cancelled, but did not change"
      Person.supervisor.update_task given, :status=>:cancelled
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
      fail unless subject.can_claim?(task) == subject.update_task(task, :owner=>subject)
      task.reload.owner == subject
    end
  end

  # Expecting that subject is able to delegate task to one of its potential owners.
  def able_to_delegate_task
    simple_matcher "be offered/able to delegate task" do |given|
      task = Task.make_active
      fail unless subject.can_delegate?(task, Person.potential) == subject.update_task(task, :owner=>Person.potential)
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
      fail unless subject.can_suspend?(task) == subject.update_task(task, :status=>:suspended)
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
      fail unless subject.can_resume?(task) == subject.update_task(task, :status=>:available)
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
      fail unless subject.can_cancel?(task) == subject.update_task(task, :status=>:cancelled)
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
      fail unless subject.can_complete?(task) == subject.update_task(task, :status=>:completed)
      task.reload.status == :completed
    end
  end

  def able_to_change_task(*attrs)
    simple_matcher "be able to change task" do |given|
      { :title=>'new title', :priority=>5, :due_on=>Date.tomorrow, :data=>{ 'foo'=>'bar' } }.
        all? { |attr, value| subject.update_task(Task.make_active, attr=>value) == (attrs.empty? || attrs.include?(attr)) }
    end
  end

end
