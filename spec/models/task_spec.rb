require File.dirname(__FILE__) + '/../spec_helper'


describe Task, 'to_param' do
  include Specs::Tasks

  it 'should return nil unless task exists in database' do
    Task.new.to_param.should be_nil
  end

  it 'should begin with task ID' do
    Task.create default_task
    Task.first.to_param.to_i.should == Task.first.id
  end

  it 'should include task title' do
    Task.create default_task.merge(:title=>'Task Title')
    Task.first.to_param[/^\d+-(.*)/, 1].should == 'Task-Title'
  end

  it 'should properly encode task title' do
    Task.create default_task.merge(:title=>'Test:encoding, ignoring "unprintable" characters')
    Task.first.to_param[/^\d+-(.*)/, 1].should == 'Test-encoding-ignoring-unprintable-characters'
  end

  it 'should remove redundant hyphens' do
    Task.create default_task.merge(:title=>'-Test  redundant--hyphens--')
    Task.first.to_param[/^\d+-(.*)/, 1].should == 'Test-redundant-hyphens'
  end

  it 'should deal gracefully with missing title' do
    Task.create default_task.merge(:title=>'')
    Task.first.to_param.should =~ /^\d+$/
  end

  it 'should leave UTF-8 text alone' do
    Task.create default_task.merge(:title=>'josé')
    Task.first.to_param[/^\d+-(.*)/, 1].should == 'josé'
  end

end


describe Task, 'etag' do
  include Specs::Tasks

  before do
    @task = Task.create(default_task)
  end

  it 'should be hex digest' do
    Task.create default_task
    Task.first.etag.should =~ /^[0-9a-f]{32}$/
  end

  it 'should remain the same if task not modified' do
    Task.create default_task
    Task.first.etag.should == Task.first.etag
  end

  it 'should be different for two different tasks' do
    Task.create(default_task).etag.should_not == Task.create(default_task).etag
  end

  it 'should change whenever task is saved' do
    Task.create default_task
    lambda { Task.first.update_attributes! :priority=>2 }.should change { Task.first.etag }
  end

end


describe Task, 'state' do
  include Specs::Tasks

  # Returns a task in the specified state.  No validation checks are made.
  # Applies optional attributes to task at creation.
  def task_in_state(state, attributes = {})
    task = Task.create(default_task.merge(attributes))
    Task.update_all ["state = ?", state], ["id=?", task.id]
    Task.find(task.id)
  end

  # Returns true if task can transition to specified state.
  def can_transition?(task, state)
    task.state = state
    task.save && task.state == state
  end

  it 'should not allow mass assignment' do
    task = Task.create(default_task.merge(:state=>'active'))
    task.state.should == 'reserved'
    lambda { task.update_attributes :state=>'active' }.should change(task, :state).to('ready')
  end

  it 'should be required to save task' do
    task = Task.new(default_task)
    task.state = nil ; task.save
    task.should have(1).error_on(:state)
  end

  it 'should be one of enumerated values' do
    task = Task.new(default_task)
    task.state = 'active' ; task.save
    task.should have(:no).errors
    task.state = 'unsupported' ; task.save
    task.should have(1).error_on(:state)
  end

  it 'should begin as reserved' do
    Task.create default_task
    Task.first.state.should == 'reserved'
  end

  it 'should not transition to reserved from any other state' do
    Task::STATES.each do |from|
      can_transition?(task_in_state(from), 'reserved').should be_false
    end
  end

  it 'should transition to ready on first update' do
    task = task_in_state('reserved')
    lambda { task.save }.should change(task, :state).to('ready')
  end

  it 'should transition from reserved to active if associated with owner' do
    task = task_in_state('reserved')
    lambda { task.owner = person('owner') ; task.save }.should change(task, :state).to('active')
  end

  it 'should not transition to ready from active' do
    task = task_in_state('active', :owner=>person('owner'))
    lambda { task.state = 'ready' ; task.save }.should_not change(task, :state)
  end

  it 'should transition from ready to active if owner specified' do
    task = task_in_state('ready')
    lambda { task.owner = person('owner') ; task.save }.should change(task, :state).to('active')
  end

  it 'should transition to ready from active if owner removed' do
    task = task_in_state('active', :owner=>person('owner'))
    lambda { task.owner = nil ; task.save }.should change(task, :state).to('ready')
  end

  it 'should transition from ready to suspended and back' do
    task = task_in_state('ready')
    can_transition?(task, 'suspended').should be_true
    can_transition?(task, 'ready').should be_true
  end

  it 'should transition from active to suspended and back' do
    task = task_in_state('active', :owner=>person('owner'))
    can_transition?(task, 'suspended').should be_true
    can_transition?(task, 'active').should be_true
  end

  it 'should transition from ready to active if has one potential owner' do
    task = task_in_state('ready')
    lambda { task.potential_owners = person('owner') ; task.save }.should change(task, :state).to('active')
    task.owner.should == person('owner')
  end

  it 'should not transition from ready to active if more than one potential owner' do
    task = task_in_state('ready', :potential_owners=>people('owner', 'other'))
    task.state.should == 'ready'
    task.owner.should be_nil
  end

  it 'should transition to completed only from active' do
    Task::STATES.each do |from|
      can_transition?(task_in_state(from, :owner=>person('owner')), 'completed').should be(from == 'active' || from == 'completed')
    end
  end

  it 'should not transition to completed without owner' do
    [nil, person('owner')].each do |owner|
      can_transition?(task_in_state('active', :owner=>owner), 'completed').should be(!owner.nil?)
    end
  end

  it 'should not change from completed to any other state' do
    Task::STATES.each do |to|
      can_transition?(task_in_state('completed', :owner=>person('owner')), to).should be(to == 'completed')
    end
  end

  it 'should transition to cancelled from any other state but completed' do
    Task::STATES.each do |from|
      can_transition?(task_in_state(from), 'cancelled').should be(from != 'completed')
    end
  end

  it 'should not change from cancelled to any other state' do
    Task::STATES.each do |to|
      can_transition?(task_in_state('cancelled'), to).should be(to == 'cancelled')
    end
  end

end


describe Task, 'priority' do
  include Specs::Tasks

  it 'should default to 1' do
    Task.new.priority.should == 1
  end

  it 'should allow values from 1 to 3' do
    priorities = Array.new(5) { |i| i }
    priorities.map { |p| Task.new(default_task.merge(:priority=>p)).valid? }.should eql([false] + [true] * 3 + [false])
  end

  it 'should accept string value' do
    Task.create default_task 
    lambda { Task.first.update_attributes! :priority=>'2' }.should change { Task.first.priority }.to(2)
  end

  it 'should accept nil and reset to default' do
    Task.create default_task.merge(:priority=>2)
    lambda { Task.first.update_attributes! :priority=>nil }.should change { Task.first.priority }.to(1)
  end

end


describe Task, 'title' do
  include Specs::Tasks

  it 'should be required' do
    Task.new(default_task.except(:title)).should have(1).error_on(:title)
  end

end


describe Task, 'due_on' do
  include Specs::Tasks

  before :each do
    @task = Task.new(default_task)
  end

  it 'should not be required' do
    Task.create(default_task.except(:due_on)).should have(:no).errors
  end

  it 'should accept time and return date' do
    now = Time.now
    lambda { @task.update_attributes! :due_on=>now ; @task.reload }.should change(@task, :due_on).to(now.to_date)
  end

  it 'should accept date and return it' do
    today = Date.today
    lambda { @task.update_attributes! :due_on=>today ; @task.reload }.should change(@task, :due_on).to(today)
  end

  it 'should accept ISO 8601 date string and return date' do
    today = Date.today
    lambda { @task.update_attributes! :due_on=>today.to_s ; @task.reload }.should change(@task, :due_on).to(today)
  end

  it 'should accept ISO 8601 time string and return date' do
    now = Time.now
    lambda { @task.update_attributes! :due_on=>now.iso8601 ; @task.reload }.should change(@task, :due_on).to(now.to_date)
  end

  it 'should accept blank string and set to nil' do
    @task.update_attributes! :due_on=>Date.today
    lambda { @task.update_attributes! :due_on=>'' ; @task.reload }.should change(@task, :due_on).to(nil)
  end

end


describe Task, 'url', :shared=>true do

  it 'should be tested for validity' do
    Task.new(@field=>'http://+++').should have(1).error_on(@field)
  end

  it 'should allow HTTP URLS' do
    Task.new(@field=>'http://test.host/do').should have(:no).errors_on(@field)
  end

  it 'should allow HTTPS URLS' do
    Task.new(@field=>'https://test.host/do').should have(:no).errors_on(@field)
  end

  it 'should not allow other URL schemes' do
    Task.new(@field=>'ftp://test.host/do').should have(1).error_on(@field)
  end

  it 'should store normalized URL' do
    task = Task.new(@field=>'HTTP://Test.Host/Foo')
    task.should have(:no).errors_on(@field)
    task.send(@field).should eql('http://test.host/Foo')
  end

  it 'should be modifiable' do
    task = Task.new(@field=>'http://test.host/view')
    lambda { task.update_attributes @field=>'http://test.host/' }.should change(task, @field).to('http://test.host/')
  end

end


describe Task, 'frame_url' do
  include Specs::Tasks
  it_should_behave_like 'Task url'

  before :all do
    @field = :frame_url
  end

  it 'should be required for active task' do
    Task.new.should have(1).errors_on(:frame_url)
  end

end


describe Task, 'outcome_url' do
  include Specs::Tasks
  it_should_behave_like 'Task url'

  before :all do
    @field = :outcome_url
  end

  it 'should be optional' do
    Task.new.should have(:no).errors_on(:outcome_url)
  end

end


describe Task, 'outcome_type' do
  include Specs::Tasks

  def outcome_values(mime_type)
    default_task.merge(:outcome_url=>'http://test.host/outcome', :outcome_type=>mime_type)
  end

  it 'should be ignored unless outcome URL specified' do
    task = Task.create!(outcome_values(Mime::XML).except(:outcome_url))
    Task.find(task.id).outcome_type.should be_nil
  end

  it 'should default to Mime::XML' do
    task = Task.create!(outcome_values(nil))
    Task.find(task.id).outcome_type.should eql(Mime::XML.to_s)
  end

  it 'should accept Mime::XML' do
    task = Task.create!(outcome_values(Mime::XML))
    Task.find(task.id).outcome_type.should eql(Mime::XML.to_s)
  end

  it 'should accept Mime::JSON' do
    task = Task.create!(outcome_values(Mime::JSON))
    Task.find(task.id).outcome_type.should eql(Mime::JSON.to_s)
  end

  it 'should accept all applicable MIME types' do
    Task::OUTCOME_MIME_TYPES.each do |mime_type|
      task = Task.create!(outcome_values(mime_type))
      Task.find(task.id).outcome_type.should eql(mime_type.to_s)
    end
  end

  it 'should accept all applicable MIME types as content type' do
    Task::OUTCOME_MIME_TYPES.each do |mime_type|
      task = Task.create!(outcome_values(mime_type.to_s))
      Task.find(task.id).outcome_type.should eql(mime_type.to_s)
    end
  end

  it 'should accept all applicable MIME types as extension name' do
    Task::OUTCOME_MIME_TYPES.each do |mime_type|
      task = Task.create!(outcome_values(mime_type.to_sym.to_s))
      Task.find(task.id).outcome_type.should eql(mime_type.to_s)
    end
  end

  it 'should reject unsupported MIME types' do
    Task.new(outcome_values(Mime::ATOM)).should have(1).error_on(:outcome_type)
  end

end


describe Task, 'data' do
  include Specs::Tasks

  before :each do
  #  @task = Task.create!(default_task)
  end

  it 'should be empty hash by default' do
    Task.new.data.should == {}
  end

  it 'should return nothing for new task' do
    Task.create default_task.except(:data)
    Task.first.data.should == {}
  end

  it 'should accept argument from mass assignment' do
    Task.create default_task
    lambda { Task.first.update_attributes :data=>{'foo'=>'bar'} }.should change { Task.first.data }.to('foo'=>'bar')
  end

  it 'should accept nil' do
    Task.create default_task.merge(:data=>{'foo'=>'bar'})
    lambda { Task.first.update_attributes :data=>nil }.should change { Task.first.data }.to({})
  end

  it 'should reject any other value' do
    lambda { Task.create default_task.merge(:data=>[]) }.should raise_error(ArgumentError)
    lambda { Task.create default_task.merge(:data=>'string') }.should raise_error(ArgumentError)
  end

end


describe Task, 'token' do
  include Specs::Tasks

  before :each do
    @creator = person('creator')
    @owner = person('owner')
    @task = Task.new(default_task.merge(:creator=>@creator, :owner=>@owner))
    @creator_token = @task.token_for(@creator)
    @owner_token = @task.token_for(@owner)
  end

  it 'should be hex digest' do
    @creator_token.should match(/^[a-f0-9]{32,}$/)
    @owner_token.should match(/^[a-f0-9]{32,}$/)
  end

  it 'should be consistent for a given person' do
    @creator_token.should eql(@task.token_for(@creator))
    @owner_token.should eql(@task.token_for(@owner))
  end

  it 'should be different for different people' do
    @creator_token.should_not eql(@owner_token)
  end

  it 'should resolve back to person' do
    @task.authorize(@creator_token).should be(@creator)
    @task.authorize(@owner_token).should be(@owner)
  end

  it 'should resolve only if person is a stakeholder' do
    lambda { @task.owner = nil }.should change { @task.authorize(@owner_token) }.from(@owner).to(nil)
  end

  it 'should rely one protected attribute access key' do
    lambda { @task.update_attributes! :access_key=>'foo' }.should_not change(@task, :access_key)
  end

end


describe Task, 'stakeholder?' do
  include Specs::Tasks

  before :all do
    @task = Task.new(@roles = all_roles)
    @task.excluded_owners = [person('excluded'), @task.potential_owners[1]]
    @task.save
  end
  
  it 'should return true if person associated with task' do
    allowed = @roles.map { |role, people| Array(people) }.flatten - @task.excluded_owners
    allowed.size.should > 0
    allowed.each { |person| @task.stakeholder?(person).should be_true }
  end

  it 'should return false if person not associated with task' do
    @task.stakeholder?(person(:unknown)).should be_false
  end

  it 'should return true for task admin' do
    @task.stakeholder?(su).should be_true
  end

  it 'should return false for excluded owner' do
    @task.excluded_owners.each { |person| @task.stakeholder?(person).should be_false }
  end

end


describe Task, 'stakeholders' do

  it 'should be protected attribute' do
    task = Task.new(:stakeholders=>[Stakeholder.new])
    task.stakeholders.should be_empty
    lambda { task.update_attributes :stakeholders=>[Stakeholder.new] }.should_not change(task, :stakeholders)
  end

end


describe Task, 'version' do
  include Specs::Tasks

  before :each do
    @task = Task.create!(default_task)
  end

  it 'should start at zero' do
    @task.version.should eql(0)
  end

  it 'should increment when task saved' do
    5.times do |n|
      lambda { @task.save }.should change(@task, :version).from(n).to(n + 1)
    end
  end

end


describe Task, 'etag' do
  include Specs::Tasks

  before :each do
    @task = Task.create!(default_task)
  end

  it 'should return same value if task not udpated' do
    @task.etag.should eql(@task.etag)
  end

  it 'should change when task updated' do
    3.times do
      lambda { @task.save }.should change(@task, :etag)
    end
  end

  it 'should be unique across tasks' do
    @task.etag.should_not eql(Task.create!(default_task))
  end

  it 'should be MD5 hash' do
    2.times do
      @task.etag.should match(/^[a-f0-9]{32}$/)
      @task.save
    end
  end

end


describe Task, 'cancellation' do
  include Specs::Tasks

  before :each do
    @task = Task.new(default_task.merge(@roles = all_roles))
  end

  it 'should default to :admin' do
    @task.cancellation.should eql(:admin)
  end

  it 'should accept :owner' do
    lambda { @task.update_attributes! :cancellation=>:owner }.should change(@task, :cancellation).to(:owner)
  end

  it 'should allow admin to cancel the task for all values' do
    @roles.select { |role, people| Array(people).any? { |person| @task.can_cancel?(person) } }.
      map(&:first).should eql([:admins])
    @task.can_cancel?(su).should be_true
  end

  it 'should allow owner to cancel the task for the value :owner' do
    @task.cancellation = :owner
    @roles.select { |role, people| Array(people).any? { |person| @task.can_cancel?(person) } }.
      map(&:first).sort_by(&:to_s).should eql([:admins, :owner])
    @task.can_cancel?(su).should be_true
  end

end


describe Task, 'completion' do
  include Specs::Tasks

  before :all do
    @roles = all_roles
  end

  before :each do
    @task = Task.create(default_task.merge(@roles))
  end

  it 'should allow owner to complete task' do
    @roles.select { |role, people| Array(people).any? { |person| @task.can_complete?(person) } }.
      map(&:first).should eql([:owner])
  end

  it 'should not validate if completed without owner' do
    @task.status = :completed
    lambda { @task.owner = nil }.should change { @task.valid? }.to(false)
  end

end
