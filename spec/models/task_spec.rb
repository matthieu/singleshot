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


describe Task do

  subject { Task.new(defaults) }

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

    describe '#associate' do
      it('should associate person with role') { subject.associate(:role=>person('foo')).in_role(:role).should == people('foo') }
      it('should associate people with role') { subject.associate(:role=>people('foo', 'bar')).in_role(:role).should == people('foo', 'bar') }
      it('should associate no one with role') { subject.associate(:role=>nil).in_role(:role).should be_empty }
    end

    describe '#in_role' do
      it('should return all people in a given role') { subject.associate(:find=>people('foo', 'bar'), :miss=>people('baz')).
        in_role(:find).should == people('foo', 'bar') }
    end

    describe '#in_role?' do
      subject { Task.new(defaults).associate(:find=>people('foo', 'bar'), :miss=>people('baz')) }
      it('should identify all people in a given role') { [subject.in_role?(:find, 'foo'), subject.in_role?(:find, 'bar'),
                                                          subject.in_role?(:miss, 'foo')].should == [true, true, false] }
      it('should return nil if no identity given')     { subject.in_role?(:find, nil).should be_false }
    end

    describe 'owner' do
      subject { new_task }

      it { should allow_mass_assigning_of(:owner) }
      it('should be nil if no person in this role') { subject.owner.should be_nil }
      it('should return person in role owner')      { subject.associate(:owner=>owner).owner.should == owner }
      it('should accept new owner if none')         { lambda { subject.owner = owner }.should change(subject, :owner) }
      it 'should choose only potential owner by default' do
        subject.associate! :potential_owner=>people('bob', 'alice')
        lambda { subject.associate! :potential_owner=>people('alice') }.should change(subject, :owner).to(person('alice'))
      end
      it('should not have two owners') { lambda { subject.associate!(:owner=>people('foo', 'bar')) }.should raise_error }

      it { should allow_assigning('potential') } # potential owner can claim to themselves
      it { should_not allow_assigning('other') }
      it { should_not allow_assigning('excluded') }
      it { should allow_assigning('supervisor') } # supervisor can claim to anyone but excluded

      it { should_not allow_assigning('potential', 'other') }
      it { should allow_assigning('supervisor', 'potential') }
      it { should allow_assigning('supervisor', 'other') }
      it { should_not allow_assigning('supervisor', 'excluded') }
      
      it { should allow_delegation('owner', 'potential') } # Can delegate to another potential owner, or noone (release),
      it { should_not allow_delegation('owner', 'other') } # but can't delegate to random person.
      it { should_not allow_delegation('owner', 'excluded') }
      it { should allow_delegation('owner', nil) }
      it { should_not allow_delegation('other', 'other') }  # Random person can't delegate to themselves, neither can potential owners.
      it { should_not allow_delegation('potential', 'potential') }
      it { should allow_delegation('supervisor', 'other') } # Supervisor can delegate to anyone, except excluded owners.
      it { should_not allow_delegation('supervisor', 'excluded') }

    end

  end

  # -- Status --
  describe 'status' do

    it { should have_attribute(:status, :string, :null=>false) }
    it { should allow_mass_assigning_of(:status) }
    it('should not allow random values') { subject.status = :random ; subject.should have(1).error_on(:status) }

    describe 'available' do
      subject { new_task }

      it('should be the initial status for new tasks')            { Task.new(:status=>'active').status.should == 'available' }
      it { should change_status_to('active', "with new owner")    { subject.update_attributes! :owner=>owner } }
      it { should_not change_status("on its own accord")          { subject.save! } }
      it { should honor_cancellation_policy }
      it { should_not change_status_to('completed')               { supervisor.update_task subject, :owner=>owner, :status=>'completed' } }
    end

    describe 'active' do
      subject { new_task(:status=>'active') }

      it('should be status for owned tasks')                  { subject.status.should == 'active' }
      it { should change_status_to('available', "if no owner") { owner.update_task subject, :owner=>nil } }
      it { should_not change_status("with owner change")      { owner.update_task subject, :owner=>potential } }
      it { should change_status_to('suspended', "if suspended by supervisor")  { supervisor.update_task subject, :status=>'suspended' } }
      it { should_not change_status("unless suspended by supervisor")         { owner.update_task subject, :status=>'suspended' } }
      it { should honor_cancellation_policy }
      it { should change_status_to('completed', "when completed by owner")     { owner.update_task subject, :status=>'completed' } }
      it { should_not change_status_to('completed', "unless by owner")         { supervisor.update_task subject, :status=>'completed' } }
    end

    describe 'suspended' do
      subject { new_task(:status=>'suspended') }

      it { should change_status_to('available', "if resumed and no owner") { supervisor.update_task! subject, :status=>'active' } }
      it { should change_status_to('active', "if resumed with owner")      { supervisor.update_task! subject, :status=>'available', :owner=>owner } }
      it { should_not change_status("unless resumed by supervisor")       { owner.update_task subject, :status=>'active' } }
      it { should honor_cancellation_policy }
      it { should_not change_status_to('completed')                        { owner.update_task subject, :owner=>owner, :status=>'completed' } }
    end

    describe 'completed' do
      subject { new_task(:status=>'completed') }

      it { should be_in_terminal_state }
      it { should be_readonly }
    end

    describe 'cancelled' do
      subject { new_task(:status=>'cancelled') }

      it { should be_in_terminal_state }
      it { should be_readonly }
    end

  end

  it { should have_attribute(:data, :text, :null=>false) }
  it { should allow_mass_assigning_of(:data) }
  it('should have empty hash as default data')  { subject.data.should be_instance_of(Hash) }
  it('should allowing assigning nil to data')   { subject.data = nil; subject.data.should == {} }
  it('should allowing assigning "" to data')    { subject.data = ""; subject.data.should == {} }
  it('should validate data is a hash')          { subject.data = 'foo' ; subject.should have(1).error_on(:data) }
  it('should store and retrieve data')          { subject.update_attributes(:data=>{ 'foo'=>'bar'})
                                                  subject.reload.data.should == { 'foo'=>'bar' } }

  it { should have_attribute(:access_key, :string, :null=>false, :limit=>40) }
  it { should_not allow_mass_assigning_of(:access_key) }
  it('should create SHA-like access key')                 { subject.access_key.should look_like_sha }
  it('should give each task unique access key')           { new_tasks('foo', 'bar', 'baz').map(&:access_key).uniq.size.should be(3) }

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
      supervisor.update_task given, :status=>'cancelled'
    end
  end

  # Expecting that person {by} can assign task to person {to}, or if unspecified claim it to
  # themselves. The task has no owner, but people in other roles (potential, supervisor, excluded, etc).
  # For example:
  #   it { should allow_assigning 'supervisor' }
  def allow_assigning(by, to = nil)
    simple_matcher do |given, matcher|
      matcher.description = "allow #{to ? 'assigning' : 'claiming'} by #{by}"
      matcher.description << " #{to}" if to
      matcher.failure_message = "expected that #{by} can assign task to #{to || 'themselves'}"
      matcher.negative_failure_message = "expected that #{by} could not assign task to #{to || 'themselves'}"
      wrap_expectation matcher do
        person(by).update_task subject, :owner=>person(to || by)
      end
    end
  end

  # Expecting that person {by} can delegate task to person {to}, or if unspecified release it to
  # any available potential owner. The task is assigned to an owner, and other roles exist (potential,
  # excluded, etc). For example:
  #   it { should allow_delegation 'owner', 'potential' }
  def allow_delegation(by, to)
    simple_matcher "allow #{by} to delegate to #{to || 'no one'}" do |given, matcher|
      subject.associate! :owner=>owner
      matcher.failure_message = "expected that #{by} can delegate task to #{to || 'no one'}"
      matcher.negative_failure_message = "expected that #{by} could not delegate task to #{to || 'no one'}"
      wrap_expectation matcher do
        person(by).update_task subject, :owner=>(to && person(to))
      end
    end
  end

end
