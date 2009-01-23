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


  it { should have_created_at_timestamp }
  it { should have_updated_at_timestamp }

end

=begin
describe Task do

  describe 'to_param' do

    it 'should return nil unless task exists in database' do
      Task.new.to_param.should be_nil
    end

    it 'should begin with task ID' do
      Task.create!(defaults).to_param.to_i.should == Task.last.id
    end

    it 'should include task title' do
      Task.create!(defaults(:title=>'Task Title')).to_param[/^\d+-(.*)/, 1].should == 'Task-Title'
    end

    it 'should properly encode task title' do
      Task.create!(defaults(:title=>'Test:encoding, ignoring "unprintable" characters')).
        to_param[/^\d+-(.*)/, 1].should == 'Test-encoding-ignoring-unprintable-characters'
    end

    it 'should remove redundant hyphens' do
      Task.create!(defaults(:title=>'-Test  redundant--hyphens--')).to_param[/^\d+-(.*)/, 1].should == 'Test-redundant-hyphens'
    end

    it 'should deal gracefully with missing title' do
      Task.create!(defaults(:title=>'--')).to_param.should =~ /^\d+$/
    end

    it 'should leave UTF-8 text alone' do
      Task.create!(defaults(:title=>'jösé')).to_param[/^\d+-(.*)/, 1].should == 'jösé'
    end

  end


  describe 'version' do

    it 'should begin at zero' do
      Task.create!(defaults).version.should == 0 
    end

    it 'should increment each time task is updated' do
      Task.create! defaults
      lambda { Task.last.update_attributes :priority=>1 }.should change { Task.last.version }.from(0).to(1)
      lambda { Task.last.update_attributes :due_on=>Time.now }.should change { Task.last.version }.from(1).to(2)
    end
  end


  describe 'etag' do

    it 'should be hex digest' do
      Task.create!(defaults).etag.should =~ /^[0-9a-f]{32}$/
    end

    it 'should remain the same if task not modified' do
      Task.create! defaults
      Task.last.etag.should == Task.last.etag
    end

    it 'should be different for two different tasks' do
      Task.create!(defaults).etag.should_not == Task.create(defaults).etag
    end

    it 'should change whenever task is saved' do
      Task.create! defaults
      lambda { Task.last.update_attributes! :priority=>1 }.should change { Task.last.etag }
      lambda { Task.last.update_attributes! :due_on=>Time.now }.should change { Task.last.etag }
    end

  end


  describe 'status' do

    it 'should start as ready' do
      Task.create!(defaults).status.should == 'ready'
    end

    it 'should only accept supported value' do
      Task.create(:status=>'unsupported').should have(1).error_on(:status)
    end

    it 'should allow starting in reserved' do
      Task.create!(defaults(:status=>'reserved')).status.should == 'reserved'
    end

    it 'should not transition to reserved from any other status' do
      for status in Task::STATUSES - ['reserved']
        task_with_status(status).can_transition?('reserved').should be_false
      end
    end

    it 'should start as ready if started as active but not associated with owner' do
      Task.create!(defaults(:status=>'active')).status.should == 'ready'
    end

    it 'should start as active if started as ready and associated with owner' do
      Task.create!(defaults(:owner=>person('owner'))).status.should == 'active'
    end

    it 'should start as active if started as ready and associated with one potential owner' do
      Task.create!(defaults(:potential_owners=>people('owner'))).status.should == 'active'
    end

    it 'should start as ready if started as ready and associated with several potential owners' do
      Task.create!(defaults(:potential_owners=>people('foo', 'bar'))).status.should == 'ready'
    end

    it 'should transition from ready to active when associated with owner' do
      task = task_with_status('ready')
      lambda { task.update_attributes :owner=>person('owner') }.should change(task, :status).to('active')
    end

    it 'should transition from active to ready when owner removed' do
      task = task_with_status('active')
      lambda { task.update_attributes :owner=>nil }.should change(task, :status).to('ready')
    end

    it 'should not accept suspended as initial value' do
      Task.create(defaults(:status=>'suspended')).should have(1).error_on(:status)
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
        task_with_status(status).can_transition?('completed', :modified_by=>person('owner')).should == (status =='active')
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
      for status in Task::STATUSES - ['reserved', 'cancelled']
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
      Task.new(defaults.except(:title)).should have(1).error_on(:title)
    end

    it 'should not be empty' do
      Task.new(defaults.merge(:title=>' ')).should have(1).error_on(:title)
    end

  end


  describe 'priority' do

    it 'should default to 2' do
      Task.create(defaults.except(:priority)).priority.should == 2
    end

    it 'should allow values from 1 to 3' do
      priorities = Array.new(5) { |i| i }
      priorities.map { |p| Task.new(defaults(:priority=>p)).valid? }.should eql([false] + [true] * 3 + [false])
    end

    it 'should accept string value' do
      Task.create(defaults(:priority=>'1')).priority.should == 1
    end

    it 'should accept nil and reset to default' do
      Task.create defaults(:priority=>1)
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

    it 'should be optional' do
      Task.create(defaults.except(:due_on)).should have(:no).errors
    end

    it 'should accept time and return date' do
      now = Time.now
      Task.create! defaults(:due_on=>now)
      Task.last.due_on.should == now.to_date
    end

    it 'should accept date and return it' do
      today = Date.today
      Task.create! defaults(:due_on=>today)
      Task.last.due_on.should == today
    end

    it 'should accept ISO 8601 date string and return date' do
      today = Date.today
      Task.create! defaults(:due_on=>today.to_s)
      Task.last.due_on.should == today
    end

    it 'should accept ISO 8601 time string and return date' do
      now = Time.now
      Task.create! defaults(:due_on=>now.iso8601)
      Task.last.due_on.should == now.to_date
    end

    it 'should accept blank string as nil' do
      Task.create! defaults(:due_on=>Time.now)
      Task.last.update_attributes :due_on=>''
      Task.last.due_on.should be_nil
    end

  end


  describe 'over_due?' do

    it 'should be false if no due date' do
      Task.create(defaults).over_due?.should be_false
    end

    it 'should be false if due date in the future' do
      Task.create(defaults(:due_on=>Date.tomorrow)).over_due?.should be_false
    end

    it 'should be false if due today' do
      Task.create(defaults(:due_on=>Date.today)).over_due?.should be_false
    end

    it 'should be true if due date in the past' do
      Task.create(defaults(:due_on=>Date.yesterday)).over_due?.should be_true
    end

    it 'should be true only when task is ready or active' do
      for status in Task::STATUSES
        task_with_status(status, :due_on=>Date.yesterday).over_due?.should == (status == 'ready' || status == 'active')
      end
    end

    it 'should respect current time zone'

  end


  #pending 'ranking'

  #pending 'modified_by'

  #pending 'with_stakeholders'

  #pending 'for_stakeholder'


  describe 'data' do

    it 'should be empty hash by default' do
      Task.new.data.should == {}
    end

    it 'should return nothing for new task' do
      Task.create defaults.except(:data)
      Task.last.data.should == {}
    end

    it 'should accept argument for mass assignment' do
      Task.create defaults
      lambda { Task.last.update_attributes :data=>{'foo'=>'bar'} }.should change { Task.last.data }.to('foo'=>'bar')
    end

    it 'should accept nil' do
      Task.create defaults(:data=>{'foo'=>'bar'})
      lambda { Task.last.update_attributes :data=>nil }.should change { Task.last.data }.to({})
    end

    it 'should reject any other value' do
      Task.create(defaults(:data=>[])).should have(1).error_on(:data)
      Task.create(defaults(:data=>'string')).should have(1).error_on(:data)
    end

  end

end


describe Task::Rendering do
  it 'should store perform_url attribute' do
    Task.create! defaults(:perform_url=>'http://perform/')
    Task.last.rendering.perform_url.should == 'http://perform/'
  end

  it 'should store details_url attribute' do
    Task.create! defaults(:details_url=>'http://details/')
    Task.last.rendering.details_url.should == 'http://details/'
  end

  it 'should store integrated_ui attribute' do
    Task.create! defaults(:perform_url=>'http://perform/', :integrated_ui=>true)
    Task.last.rendering.integrated_ui.should be_true
  end

  it 'should not have integrated_ui without perform_url' do
    Task.new(defaults(:integrated_ui=>true)).rendering.integrated_ui.should be_false
  end

  it 'should default integrated_ui attribute to false' do
    Task.new(defaults(:perform_url=>'http://perform/')).rendering.integrated_ui.should be_false
  end

  it 'should use completion button if no perform_url' do
    Task.new(defaults).rendering.use_completion_button?.should be_true
    Task.new(defaults(:details_url=>'http://details/')).rendering.use_completion_button?.should be_true
  end

  it 'should use completion button if perform_url but no integrated_ui' do
    Task.new(defaults(:perform_url=>'http://perform/')).rendering.use_completion_button?.should be_true
  end

  it 'should not use completion button if perform_url and integrated_ui' do
    Task.new(defaults(:perform_url=>'http://perform/', :integrated_ui=>true)).rendering.use_completion_button?.should be_false
  end

  it 'should have no render_url without perform_url or details_url' do
    Task.new.rendering.render_url(true).should be_nil
    Task.new.rendering.render_url(false).should be_nil
  end

  it 'should render to owner using perform_url if available' do
    Task.new(:perform_url=>'http://perform/').rendering.render_url(true).should == 'http://perform/'
  end

  it 'should render to owner using perform_url even if details_url given' do
    Task.new(:perform_url=>'http://perform/', :details_url=>'http://details/').rendering.render_url(true).should == 'http://perform/'
  end

  it 'should render to owner using details_url if no perform_url' do
    Task.new(:details_url=>'http://details/').rendering.render_url(true).should == 'http://details/'
  end

  it 'should render to anyone else using details_url if available' do
    Task.new(:details_url=>'http://details/').rendering.render_url(false).should == 'http://details/'
  end

  it 'should not render to anyone else using perform_url' do
    Task.new(:perform_url=>'http://perform/').rendering.render_url(false).should be_nil
    Task.new(:perform_url=>'http://perform/', :details_url=>'http://details/').rendering.render_url(false).should == 'http://details/'
  end

  it 'should not yield from render_url if no suitable URL' do
    Task.new.rendering.render_url(true, :integrated_ui=>true) { fail }.should be_nil
    Task.new.rendering.render_url(false, :integrated_ui=>true) { fail }.should be_nil
  end

  it 'should include query parameters for integrated UI' do
    Task.new(:perform_url=>'http://perform/', :integrated_ui=>true).rendering.
      render_url(true, 'foo'=>'bar').should == 'http://perform/?foo=bar'
    Task.new(:perform_url=>'http://perform/', :details_url=>'http://details/', :integrated_ui=>true).rendering.
      render_url(false, 'foo'=>'bar').should == 'http://details/?foo=bar'
  end

  it 'should yield and include query parameters for integrated UI' do
    Task.new(:perform_url=>'http://perform/', :integrated_ui=>true).rendering.
      render_url(true) { { 'foo'=>'bar' } }.should == 'http://perform/?foo=bar'
    Task.new(:perform_url=>'http://perform/', :details_url=>'http://details/', :integrated_ui=>true).rendering.
      render_url(false) { { 'foo'=>'bar' } }.should == 'http://details/?foo=bar'
  end

  it 'should escape query parameters for integrated UI' do
    Task.new(:perform_url=>'http://perform/', :integrated_ui=>true).rendering.
      render_url(true, 'url'=>'http://integated').should == 'http://perform/?url=http%3A%2F%2Fintegated'
  end

  it 'should not include query parameters unless integrated UI' do
    Task.new(:perform_url=>'http://perform/').rendering.render_url(true, 'foo'=>'bar').should == 'http://perform/'
  end

  it 'should be assignable from hash' do
    hash = { :perform_url=>'http://foobar/', :details_url=>'http://barfoo/', :integrated_ui=>true }
    task = Task.new
    task.attributes = { :rendering=>hash }
    hash.each do |key, value|
      task.rendering.send(key).should == value
    end
  end

  it 'should validate URLs' do
    Task.new(:perform_url=>'http://+++').should have(1).error_on(:perform_url)
    Task.new(:details_url=>'http://+++').should have(1).error_on(:details_url)
  end

  it 'should allow HTTP URLS' do
    Task.new(:perform_url=>'http://test.host/foo').should have(:no).errors
    Task.new(:details_url=>'http://test.host?foo=bar').should have(:no).errors
  end

  it 'should allow HTTPS URLS' do
    Task.new(:perform_url=>'https://test.host/foo').should have(:no).errors
    Task.new(:details_url=>'https://test.host?foo=bar').should have(:no).errors
  end

  it 'should not allow other URL schemes' do
    Task.new(:perform_url=>'ftp://test.host/foo').should have(1).error_on(:perform_url)
    Task.new(:details_url=>'file:///var/log').should have(1).error_on(:details_url)
  end

  it 'should store normalized URLs' do
    Task.create defaults(:perform_url=>'HTTP://Test.Host/Foo', :details_url=>'HTTPS://Foo:Bar@test.host?Foo=Bar')
    Task.last.perform_url.should eql('http://test.host/Foo')
    Task.last.details_url.should eql('https://Foo:Bar@test.host/?Foo=Bar')
  end

end


describe Task, 'outcome_url' do
  it_should_behave_like 'Task url'

  before :all do
    @field = :outcome_url
  end

  it 'should be optional' do
    Task.new.should have(:no).errors_on(:outcome_url)
  end

end


describe Task, 'outcome_type' do

  def outcome_values(mime_type)
    defaults(:outcome_url=>'http://test.host/outcome', :outcome_type=>mime_type)
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

  before :each do
    @creator = person('creator')
    @owner = person('owner')
    @task = Task.new(defaults(:creator=>@creator, :owner=>@owner))
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


=end
