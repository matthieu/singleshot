require File.dirname(__FILE__) + '/../spec_helper'


describe Task do
  include Specs::Tasks

  describe 'to_param' do

    it 'should return nil unless task exists in database' do
      Task.new.to_param.should be_nil
    end

    it 'should begin with task ID' do
      Task.create!(default_task).to_param.to_i.should == Task.last.id
    end

    it 'should include task title' do
      Task.create!(default_task.merge(:title=>'Task Title')).to_param[/^\d+-(.*)/, 1].should == 'Task-Title'
    end

    it 'should properly encode task title' do
      Task.create!(default_task.merge(:title=>'Test:encoding, ignoring "unprintable" characters')).
        to_param[/^\d+-(.*)/, 1].should == 'Test-encoding-ignoring-unprintable-characters'
    end

    it 'should remove redundant hyphens' do
      Task.create!(default_task.merge(:title=>'-Test  redundant--hyphens--')).to_param[/^\d+-(.*)/, 1].should == 'Test-redundant-hyphens'
    end

    it 'should deal gracefully with missing title' do
      Task.create!(default_task.merge(:title=>'--')).to_param.should =~ /^\d+$/
    end

    it 'should leave UTF-8 text alone' do
      Task.create!(default_task.merge(:title=>'jösé')).to_param[/^\d+-(.*)/, 1].should == 'jösé'
    end

  end


  describe 'version' do

    it 'should begin at zero' do
      Task.create!(default_task).version.should == 0 
    end

    it 'should increment each time task is updated' do
      Task.create! default_task
      lambda { Task.last.update_attributes :priority=>1 }.should change { Task.last.version }.from(0).to(1)
      lambda { Task.last.update_attributes :due_on=>Time.now }.should change { Task.last.version }.from(1).to(2)
    end
  end


  describe 'etag' do

    it 'should be hex digest' do
      Task.create!(default_task).etag.should =~ /^[0-9a-f]{32}$/
    end

    it 'should remain the same if task not modified' do
      Task.create! default_task
      Task.last.etag.should == Task.last.etag
    end

    it 'should be different for two different tasks' do
      Task.create!(default_task).etag.should_not == Task.create(default_task).etag
    end

    it 'should change whenever task is saved' do
      Task.create! default_task
      lambda { Task.last.update_attributes! :priority=>1 }.should change { Task.last.etag }
      lambda { Task.last.update_attributes! :due_on=>Time.now }.should change { Task.last.etag }
    end

  end


  describe 'status' do

    def task_with_status(status, attributes = nil)
      attributes ||= {}
      task = case status
      when 'active'
        Task.create!(default_task.merge(attributes).merge(:status=>status, :owner=>person('owner')))
      when 'completed'
        active = Task.create!(default_task.merge(attributes).merge(:status=>'active', :owner=>person('owner')))
        active.update_attributes :status=>'completed'
        active
      else
        Task.create!(default_task.merge(attributes).merge(:status=>status))
      end

      def task.transition_to(status, attributes = nil)
        attributes ||= {}
        update_attributes attributes.merge(:status=>status)
        self
      end
      def task.can_transition?(status, attributes = nil)
        transition_to(status, attributes).errors_on(:status).empty?
      end
      task
    end

    it 'should start as ready' do
      Task.create!(default_task).status.should == 'ready'
    end

    it 'should only accept supported value' do
      Task.create(:status=>'unsupported').should have(1).error_on(:status)
    end

    it 'should allow starting in reserved' do
      Task.create!(default_task.merge(:status=>'reserved')).status.should == 'reserved'
    end

    it 'should not transition to reserved from any other status' do
      for status in Task::STATUSES - ['reserved']
        task_with_status(status).can_transition?('reserved').should be_false
      end
    end

    it 'should start as ready if started as active but not associated with owner' do
      Task.create!(default_task.merge(:status=>'active')).status.should == 'ready'
    end

    it 'should start as active if started as ready and associated with owner' do
      Task.create!(default_task.merge(:owner=>person('owner'))).status.should == 'active'
    end

    it 'should start as active if started as ready and associated with one potential owner' do
      Task.create!(default_task.merge(:potential_owners=>people('owner'))).status.should == 'active'
    end

    it 'should start as ready if started as ready and associated with several potential owners' do
      Task.create!(default_task.merge(:potential_owners=>people('foo', 'bar'))).status.should == 'ready'
    end

    it 'should transition from ready to active when associated with owner' do
      task = task_with_status('ready')
      lambda { task.update_attributes :owner=>person('owner') }.should change(task, :status).to('active')
    end

    it 'should transition from active to ready when owner removed' do
      task = task_with_status('active')
      lambda { task.update_attributes :owner=>nil }.should change(task, :status).to('ready')
    end

    it 'should accept suspended as initial value' do
      Task.create!(default_task.merge(:status=>'suspended')).status.should == 'suspended'
    end

    it 'should transition from ready to suspended' do
      task_with_status('ready').can_transition?('suspended').should be_true
    end

    it 'should transition from suspended back to ready' do
      task_with_status('suspended').transition_to('ready').status.should == 'ready'
      task_with_status('suspended').transition_to('active').status.should == 'ready'
    end

    it 'should transition from active to suspended' do
      task_with_status('active').can_transition?('suspended').should be_true
    end

    it 'should transition from suspended back to active' do
      task_with_status('suspended', :owner=>person('owner')).transition_to('active').status.should == 'active'
      task_with_status('suspended', :owner=>person('owner')).transition_to('ready').status.should == 'active'
    end

    it 'should only transition to completed from active' do
      for status in Task::STATUSES - ['completed']
        task_with_status(status).can_transition?('completed').should == (status =='active')
      end
    end

    it 'should not transition to completed without owner' do
      task_with_status('active').can_transition?('completed', :owner=>nil).should be_false
    end

    it 'should not transition from completed to any other status' do
      for status in Task::STATUSES - ['completed']
        task_with_status('completed').can_transition?(status).should be_false
      end
    end

    it 'should transition to cancelled from any other status but completed' do
      for status in Task::STATUSES - ['cancelled']
        task_with_status(status).can_transition?('cancelled').should == (status !='completed')
      end
    end

    it 'should not transition from cancelled to any other status' do
      for status in Task::STATUSES - ['cancelled']
        task_with_status('cancelled').can_transition?(status).should be_false
      end
    end

    it 'should not allow changing of completed or cancelled tasks' do
      lambda { task_with_status('completed').update_attributes :title=>'never mind' }.should raise_error(ActiveRecord::ReadOnlyRecord)
      lambda { task_with_status('cancelled').update_attributes :title=>'never mind' }.should raise_error(ActiveRecord::ReadOnlyRecord)
    end

  end


  describe 'title' do

    it 'should be required' do
      Task.new(default_task.except(:title)).should have(1).error_on(:title)
    end

    it 'should not be empty' do
      Task.new(default_task.merge(:title=>' ')).should have(1).error_on(:title)
    end

  end


  describe 'priority' do

    it 'should default to 2' do
      Task.create(default_task.except(:priority)).priority.should == 2
    end

    it 'should allow values from 1 to 3' do
      priorities = Array.new(5) { |i| i }
      priorities.map { |p| Task.new(default_task.merge(:priority=>p)).valid? }.should eql([false] + [true] * 3 + [false])
    end

    it 'should accept string value' do
      Task.create(default_task.merge(:priority=>'1')).priority.should == 1
    end

    it 'should accept nil and reset to default' do
      Task.create default_task.merge(:priority=>1)
      lambda { Task.last.update_attributes! :priority=>nil }.should change { Task.last.priority }.to(2)
    end

  end


  describe 'high_priority?' do

    it 'should be true for priority 1' do
      Task.new(:priority=>1).high_priority?.should be_true
    end

    it 'should be false for priorities other than 1' do
      for priority in 2..3
        Task.new(:priority=>priority).high_priority?.should be_false
      end
    end

  end


  describe 'due_on' do

    it 'should not be required' do
      Task.create(default_task.except(:due_on)).should have(:no).errors
    end

    it 'should accept time and return date' do
      now = Time.now
      Task.create! default_task.merge(:due_on=>now)
      Task.last.due_on.should == now.to_date
    end

    it 'should accept date and return it' do
      today = Date.today
      Task.create! default_task.merge(:due_on=>today)
      Task.last.due_on.should == today
    end

    it 'should accept ISO 8601 date string and return date' do
      today = Date.today
      Task.create! default_task.merge(:due_on=>today.to_s)
      Task.last.due_on.should == today
    end

    it 'should accept ISO 8601 time string and return date' do
      now = Time.now
      Task.create! default_task.merge(:due_on=>now.iso8601)
      Task.last.due_on.should == now.to_date
    end

    it 'should accept blank string and set to nil' do
      Task.create! default_task.merge(:due_on=>Time.now)
      Task.last.update_attributes :due_on=>''
      Task.last.due_on.should be_nil
    end

  end


  describe 'over_due?' do

    it 'should be false if task has no due date' do
      Task.new.over_due?.should be_false
    end

    it 'should be false if task due date in the future' do
      Task.new(:due_on=>Date.tomorrow).over_due?.should be_false
    end

    it 'should be false if task due today' do
      Task.new(:due_on=>Date.today).over_due?.should be_false
    end

    it 'should be true if task due date in the past' do
      Task.new(:due_on=>Date.yesterday).over_due?.should be_true
    end

  end


  describe 'ranking'

  describe 'modified_by'

  describe 'activities'

  describe 'with_stakeholders'

  describe 'for_stakeholder'

  describe 'data' do

    it 'should be empty hash by default' do
      Task.new.data.should == {}
    end

    it 'should return nothing for new task' do
      Task.create default_task.except(:data)
      Task.last.data.should == {}
    end

    it 'should accept argument for mass assignment' do
      Task.create default_task
      lambda { Task.last.update_attributes :data=>{'foo'=>'bar'} }.should change { Task.last.data }.to('foo'=>'bar')
    end

    it 'should accept nil' do
      Task.create default_task.merge(:data=>{'foo'=>'bar'})
      lambda { Task.last.update_attributes :data=>nil }.should change { Task.last.data }.to({})
    end

    it 'should reject any other value' do
      Task.create(default_task.merge(:data=>[])).should have(1).error_on(:data)
      Task.create(default_task.merge(:data=>'string')).should have(1).error_on(:data)
    end

  end

end


=begin

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
=end
