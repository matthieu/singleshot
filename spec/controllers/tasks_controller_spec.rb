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

describe TasksController do
  
  controller_name :tasks
  before { controller.use_rails_error_handling! }

  describe 'create' do
    before { @params = { :task=>{ :title=>'expenses' } } }

    it { should route(:post, '/tasks', :controller=>'tasks', :action=>'create') }
    it ('should require authentication (HTML)')   { post(:create, @params).should redirect_to(session_url) }
    it ('should require authentication (API)')    { post(:create, @params.merge(:format=>:json)).should respond_with(401) }
    it ('should verify parameters include task')  { post(:create, @params.except(:task), as_creator).should respond_with(400) }
    it ('should require task to have a title')    { post(:create, { :task=>@params.except(:title), :format=>:json }, as_creator).should respond_with(422) }
    it ('should create new task')                 { new_task!.title.should == 'expenses' }
    it ('should set task creator to authenticated person')    { new_task!.in_role(:creator).first.should == Person.creator }
    it ('should set task supervisor to authenticated person') { new_task!.in_role(:supervisor).first.should == Person.creator }
    it ('should return status 201 Created')       { post(:create, @params.merge(:format=>:json), as_creator).should respond_with(201) }
    it ('should return location of new task')     { post(:create, @params.merge(:format=>:json), as_creator).should respond_with('Location'=>task_url(Task.last)) }
    it ('should render new task (HTML)')          { post(:create, @params.merge(:format=>:html), as_creator).should respond_with('tasks/show.html.erb') }
    it ('should render new task (JSON)')          { parse(:json, post(:create, @params.merge(:format=>:json), as_creator))['task']['title'].should == 'expenses' }
    it ('should render new task (XML)')           { parse(:xml, post(:create, @params.merge(:format=>:xml), as_creator))['task']['title'].should == 'expenses' }

    def new_task!(params = {})
      post :create, @params.merge(params), as_creator
      Task.last
    end
  end


  describe 'show' do
    before { @task = Task.make(:title=>'expenses') }
    before { @params = { :id=>@task.id } }

    it { should route(:get, '/tasks/1', :controller=>'tasks', :action=>'show', :id=>'1') }
    it ('should require authentication (HTML)')   { get(:show, @params).should redirect_to(session_url) }
    it ('should require authentication (JSON)')   { get(:show, @params.merge(:format=>:json)).should respond_with(401) }
    it ('should reject unauthorized requests')    { get(:show, @params.merge(:format=>:json), as_other).should respond_with(404) }
    it ('should render task (HTML)')              { get(:show, @params.merge(:format=>:html), as_creator).should respond_with('tasks/show.html.erb') }
    it ('should render task (JSON)')              { parse(:json, get(:show, @params.merge(:format=>:json), as_creator)).should include('task') }
    it ('should render task (XML)')               { parse(:xml, get(:show, @params.merge(:format=>:xml), as_creator)).should include('task') }
  end


  describe 'update' do
    before { @task = Task.make(:title=>'expenses') }
    before { @params = { :id=>@task.id, :task=>{ 'priority'=>1 } } }

    it { should route(:put, '/tasks/1', :controller=>'tasks', :action=>'update', :id=>'1') }
    it ('should require authentication (HTML)')   { put(:update, @params).should redirect_to(session_url) }
    it ('should require authentication (JSON)')   { put(:update, @params.merge(:format=>:json)).should respond_with(401) }
    it ('should reject unauthorized requests')    { put(:update, @params.merge(:format=>:json), as_creator).should respond_with(422) }
    it ('should verify parameters include task')  { put(:update, @params.except(:task), as_supervisor).should respond_with(400) }
    it ('should render task (HTML)')              { put(:update, @params.merge(:format=>:html), as_supervisor).should respond_with('tasks/show.html.erb') }
    it ('should render task (JSON)')              { parse(:json, put(:update, @params.merge(:format=>:json), as_supervisor)).should include('task') }
    it ('should render task (XML)')               { parse(:xml, put(:update, @params.merge(:format=>:xml), as_supervisor)).should include('task') }
    it ('should modify task')                     { lambda { put(:update, @params, as_supervisor) }.should change { Task.find(@task).priority }.to(1) }
  end




  def parse(*args)
    response = args.pop
    args.shift.to_s.should == response.content_type if Symbol === args.first
    case response.content_type
    when Mime::JSON
      ActiveSupport::JSON.decode(response.body)
    when Mime::XML
      Hash.from_xml(response.body)
    else fail "Don't know how to parse #{response.content_type}"
    end
  end


  def as_creator
    session_for(Person.creator)
  end

  def as_supervisor
    session_for(Person.supervisor)
  end

  def as_other
    session_for(Person.other)
  end
end
=begin
describe TasksController do
  
  controller_name :tasks
  before { controller.use_rails_error_handling! }

  describe 'GET /tasks/{id}' do
    before :each do
      @task = Task.create(defaults(@roles = all_roles))
      authenticate person(@roles[:admins].first)
    end

    it 'should map to /tasks/{id}' do
      route_for(:controller=>'tasks', :action=>'show', :id=>1).should eql('/tasks/1')
      lambda { route_for(:controller=>'tasks', :action=>'show') }.should raise_error(ActionController::RoutingError)
    end

    it 'should 404 if task not found' do
      lambda { get :show, :id=>0 }.should raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should 404 if task not yet active' do
      task = Task.reserve!(authenticated)
      lambda { get :show, :id=>task.id }.should raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should 404 if task already cancelled' do
      @task.status = :cancelled ; @task.save!
      lambda { get :show, :id=>@task.id }.should raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should 404 unless allowed to view task' do
      authenticate person('noone')
      lambda { get :show, :id=>@task.id }.should raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should not be visible to admin' do
      lambda { get :show, :id=>@task.id }.should_not raise_error
    end

    it 'should not be visible to owner' do
      authenticate @roles[:owner]
      lambda { get :show, :id=>@task.id }.should_not raise_error
    end

    it 'should not be visible to potential owner' do
      authenticate @roles[:potential_owners].first
      lambda { get :show, :id=>@task.id }.should_not raise_error
    end

    it 'should not be visible to excluded owners' do
      authenticate @task.potential_owners[1]
      @task.update_attributes! :excluded_owners=>[authenticated]
      lambda { get :show, :id=>@task.id }.should raise_error(ActiveRecord::RecordNotFound)
    end

  end


end








describe TasksController, 'PUT task', :shared=>true do
  before :all do
    @admin, @owner = people('admin', 'owner')
    @observer, @excluded = people('observer', 'excluded')
    @potential = people('potential', 'potential2')
  end

  before :each do
    @task = Task.create!(defaults(:admins=>@admin, :potential_owners=>@potential,
      :excluded_owners=>@excluded, :observers=>@observer))
    controller.use_rails_error_handling!
  end
  
  it 'should map to /tasks/{id}' do
    route_for(:controller=>'tasks', :action=>'update', :id=>@task.id).should eql("/tasks/#{@task.id}")
    lambda { route_for(:controller=>'tasks', :action=>'update') }.should raise_error(ActionController::RoutingError)
  end

end

describe TasksController, 'PUT reserved task' do
  before :each do
    authenticate person('admin')
    @task = Task.reserve!(authenticated)
    controller.use_rails_error_handling!
  end
  
  it 'should 400 if no input provided' do
    put :update, :id=>@task.id
    response.should be_bad_request
    @task.reload.should be_reserved
  end

  it 'should 404 if not associated with task' do
    authenticate person('unknown')
    put :update, :id=>@task.id, :task=>defaults
    response.should be_not_found
    @task.reload.should be_reserved
  end

  it 'should 200 and redirect back if task updated' do
    put :update, :id=>@task.id, :task=>defaults
    response.should redirect_to(task_url)
  end

  it 'should update task' do
    put :update, :id=>@task.id, :task=>defaults
    @task.reload
    defaults.each do |key, value|
      @task.send(key).should eql(value)
    end
  end

  it 'should change task status to active' do
    put :update, :id=>@task.id, :task=>defaults
    @task.reload.should be_active
  end

  it 'should retain task administrator if no admins specified' do
    put :update, :id=>@task.id, :task=>defaults.except(:admins)
    @task.reload.admins.should eql([authenticated])
  end

  it 'should retain authenticated admin when other admins specified' do
    admins = people('foo', 'bar')
    put :update, :id=>@task.id, :task=>defaults(:admins=>admins)
    @task.reload.admins.sort_by(&:id).should eql([authenticated] + admins)
  end

  it 'should 422 if task does not validate' do
    put :update, :id=>@task.id, :task=>defaults.except(:title)
    response.should be_unprocessable_entity
  end

  it 'should determine outcome type from content type if XML' do
    request.headers['CONTENT_TYPE'] = 'application/xml'
    put :update, :id=>@task.id, :task=>defaults
    @task.reload.outcome_type.should eql('application/xml')
  end

  it 'should determine outcome type from content type if JSON' do
    request.headers['CONTENT_TYPE'] = 'application/json'
    put :update, :id=>@task.id, :task=>defaults
    @task.reload.outcome_type.should eql('application/json')
  end

  it 'should allow changing of outcome type' do
    put :update, :id=>@task.id, :task=>defaults(:outcome_type=>'application/json')
    @task.reload.outcome_type.should eql('application/json')
  end
 
end

describe TasksController, 'PUT active task' do
  it_should_behave_like 'TasksController PUT task'

  it 'should 400 if no task input provided' do
    authenticate @admin
    put :update, :id=>@task.id
    response.should be_bad_request
  end

  it 'should 404 if not associated with task' do
    authenticate person('unknown')
    put :update, :id=>@task.id, :task=>defaults
    response.should be_not_found
  end

  it 'should allow administrator to change task' do
    authenticate @admin
    put :update, :id=>@task.id, :task=>{ :title=>'changed', :data=>{ 'foo'=>'bar'  } }
    @task.reload.title.should eql('changed')
    @task.data.should == { 'foo'=>'bar' }
  end

  it 'should allow administrator to assign task' do
    authenticate @admin
    put :update, :id=>@task.id, :task=>{ :owner=>@potential.first }
    @task.reload.owner.should eql(@potential.first)
  end

  it 'should not allow administrator to assign to excluded owner' do
    authenticate @admin
    put :update, :id=>@task.id, :task=>{ :owner=>@excluded }
    response.should be_client_error
  end

  it 'should allow potential owner to claim task' do
    authenticate @potential.first
    put :update, :id=>@task.id, :task=>{ :owner=>@potential.first }
    @task.reload.owner.should eql(@potential.first)
  end

  it 'should 404 if excluded owner attempts to claim task' do
    authenticate @excluded
    put :update, :id=>@task.id, :task=>{ :owner=>@excluded }
    response.should be_not_found
  end

  it 'should not allow anyone but administrator to assign task' do
    authenticate @potential.first
    put :update, :id=>@task.id, :task=>{ :owner=>@observer }
    @task.reload.owner.should be_nil
  end

  it 'should 200 and redirect back after update' do
    authenticate @admin
    put :update, :id=>@task.id, :task=>{}
    response.should redirect_to(task_url)
  end

  it 'should keep task status as active' do
    authenticate @admin
    put :update, :id=>@task.id, :task=>{}
    @task.reload.should be_active
  end

  it 'should allow adminstrator to change status to suspended' do
    authenticate @admin
    put :update, :id=>@task.id, :task=>{ :status=>'suspended' }
    @task.reload.should be_suspended
  end

  it 'should 403 if anyone else attempts to change task' do
    authenticate @observer
    put :update, :id=>@task.id, :task=>{}
    response.should be_forbidden
  end

  it 'should allow changing of outcome type' do
    authenticate @admin
    put :update, :id=>@task.id, :task=>{ :outcome_type=>'application/json' }
    @task.reload.outcome_type.should eql('application/json')
  end

  it 'should not change outcome type unless specified' do
    request.headers['CONTENT_TYPE'] = 'application/json'
    @task.update_attributes! :outcome_type=>'application/json'
    authenticate @admin
    put :update, :id=>@task.id, :task=>{}
    @task.reload.outcome_type.should eql('application/json')
  end
 
end

describe TasksController, 'PUT claimed task' do
  it_should_behave_like 'TasksController PUT task'

  before(:each) { @task.owner = @owner ; @task.save! }

  it 'should allow owner to release task if other potential owners' do
    authenticate @owner
    put :update, :id=>@task.id, :task=>{ :owner=>nil }
    @task.reload.owner.should be_nil
  end

  it 'should allow owner to delegate task' do
    authenticate @owner
    put :update, :id=>@task.id, :task=>{ :owner=>@observer }
    @task.reload.owner.should eql(@observer)
  end

  it 'should not allow assigning to excluded owner' do
    authenticate @owner
    put :update, :id=>@task.id, :task=>{ :owner=>@excluded }
    response.should be_client_error
    response.should have_text(/excluded owner/i)
  end

  it 'should allow owner to change task data' do
    authenticate @owner
    put :update, :id=>@task.id, :task=>{ :title=>'changed', :data=>{ 'foo'=>'bar'  } }
    @task.reload.title.should eql(defaults[:title])
    @task.data.should == { 'foo'=>'bar' }
  end

  it 'should allow administrator to change task state' do
    authenticate @admin
    put :update, :id=>@task.id, :task=>{ :title=>'changed', :data=>{ 'foo'=>'bar'  } }
    @task.reload.title.should eql('changed')
    @task.data.should == { 'foo'=>'bar' }
  end

  it 'should 403 if potential owner attempts to change task' do
    authenticate @potential.first
    put :update, :id=>@task.id, :task=>{ }
    response.should be_forbidden
  end

  it 'should 403 if potential owner claims task' do
    authenticate @potential.first
    put :update, :id=>@task.id, :task=>{ :owner=>@potential.first }
    response.should be_forbidden
  end

  it 'should 403 if owner releases task and no potential owners' do
    @task.update_attributes! :potential_owners=>@owner
    authenticate @owner
    put :update, :id=>@task.id, :task=>{ :owner=>nil }
    response.should be_forbidden
  end

end


describe TasksController, 'PUT suspended task' do
  it_should_behave_like 'TasksController PUT task'

  before(:each) { @task.owner = @owner ; @task.status = :suspended ; @task.save! }

  it 'should allow admin to change task' do
    authenticate @admin
    put :update, :id=>@task.id, :task=>{ :title=>'changed', :data=>{ 'foo'=>'bar'  } }
    @task.reload.title.should eql('changed')
    @task.data.should == { 'foo'=>'bar' }
  end

  it 'should keep task suspended' do
    authenticate @admin
    put :update, :id=>@task.id, :task=>{}
    @task.reload.should be_suspended
  end

  it 'should allow admin to change status to active' do
    authenticate @admin
    put :update, :id=>@task.id, :task=>{ :status=>'active' }
    @task.reload.should be_active
  end

  it 'should 403 if anyone else changes status to active' do
    authenticate @owner
    put :update, :id=>@task.id, :task=>{ :status=>'active' }
    response.should be_forbidden
  end

  it 'should 403 if owner attempts to change task' do
    authenticate @owner
    put :update, :id=>@task.id, :task=>{}
    response.should be_forbidden
  end

  it 'should 403 if potential owner attempts to change task' do
    authenticate @potential.first
    put :update, :id=>@task.id, :task=>{ :owner=>@potential.first }
    response.should be_forbidden
  end

end

describe TasksController, 'PUT completed task' do
  it_should_behave_like 'TasksController PUT task'

  before(:each) { @task.status = :completed ; @task.owner = @owner ; @task.save! }

  it 'should 404 if not associated with task' do
    authenticate person('unknown')
    put :update, :id=>@task.id, :task=>defaults
    response.should be_not_found
    @task.reload.should be_completed
  end

  it 'should 409 if associated with task' do
    authenticate @admin
    put :update, :id=>@task.id, :task=>defaults
    response.should be_conflict
    @task.reload.should be_completed
  end

  it 'should not change task' do
    authenticate @admin
    put :update, :id=>@task.id, :task=>defaults(:title=>'changed')
    @task.reload.title.should_not eql('changed')
  end

end

describe TasksController, 'PUT cancelled task' do
  it_should_behave_like 'TasksController PUT task'

  before(:each) { @task.status = :cancelled ; @task.save! }

  it 'should 404 if not associated with task' do
    authenticate person('unknown')
    put :update, :id=>@task.id, :task=>defaults
    response.should be_not_found
    @task.reload.should be_cancelled
  end

  it 'should 404 if associated with task' do
    authenticate @admin
    put :update, :id=>@task.id, :task=>defaults
    response.should be_not_found
    @task.reload.should be_cancelled
  end

end


describe TasksController, 'DELETE task', :shared=>true do
  before :each do
    @admin, @owner = people('admin', 'owner')
    @task = Task.create!(defaults(:admins=>@admin, :owner=>@owner))
    controller.use_rails_error_handling!
  end
  
  it 'should map to /tasks/{id}' do
    route_for(:controller=>'tasks', :action=>'destroy', :id=>@task.id).should eql("/tasks/#{@task.id}")
    lambda { route_for(:controller=>'tasks', :action=>'destroy') }.should raise_error(ActionController::RoutingError)
  end

end

describe TasksController, 'DELETE reserved task' do
  before :each do
    @admin = person('admin')
    @task = Task.reserve!(@admin)
    controller.use_rails_error_handling!
  end
  
  it 'should 404 if not associated with task' do
    authenticate person('unknown')
    delete :destroy, :id=>@task.id
    response.should be_not_found
    Task.should have(1).record
  end

  it 'should 200 if task deleted' do
    authenticate @admin
    delete :destroy, :id=>@task.id
    response.should be_ok
    response.body.should be_blank
  end

  it 'should delete task' do
    authenticate @admin
    delete :destroy, :id=>@task.id
    Task.should have(:no).records
  end

end

describe TasksController, 'DELETE active task' do
  it_should_behave_like 'TasksController DELETE task'

  it 'should 404 if not associated with task' do
    authenticate person('unknown')
    delete :destroy, :id=>@task.id
    response.should be_not_found
    @task.reload.should be_active
  end

  it 'should 403 if not task administrator' do
    authenticate @owner
    delete :destroy, :id=>@task.id
    response.should be_forbidden
    @task.reload.should be_active
  end

  it 'should 200 if task cancelled' do
    authenticate @admin
    delete :destroy, :id=>@task.id
    response.should be_ok
    response.body.should be_blank
  end

  it 'should change task status to cancelled' do
    authenticate @admin
    delete :destroy, :id=>@task.id
    @task.reload.should be_cancelled
  end

  it 'should not cancel if owner and cancellation policy is admin' do
    authenticate @owner
    delete :destroy, :id=>@task.id
    @task.reload.should be_active
  end

  it 'should cancel if owner and cancellation policy is owner' do
    @task.update_attributes! :cancellation=>:owner
    authenticate @owner
    delete :destroy, :id=>@task.id
    @task.reload.should be_cancelled
  end

end

describe TasksController, 'DELETE suspended task' do
  it_should_behave_like 'TasksController DELETE task'

  before(:each) { @task.status = :suspended ; @task.save! }

  it 'should 200 if task cancelled' do
    authenticate @admin
    delete :destroy, :id=>@task.id
    response.should be_ok
    response.body.should be_blank
  end

  it 'should change task status to cancelled' do
    authenticate @admin
    delete :destroy, :id=>@task.id
    @task.reload.should be_cancelled
  end

end

describe TasksController, 'DELETE completed task' do
  it_should_behave_like 'TasksController DELETE task'

  before(:each) { @task.status = :completed ; @task.save! }

  it 'should 404 if not associated with task' do
    authenticate person('unknown')
    delete :destroy, :id=>@task.id
    response.should be_not_found
    @task.reload.should be_completed
  end

  it 'should 409 if associated with task' do
    authenticate @admin
    delete :destroy, :id=>@task.id
    response.should be_conflict
    @task.reload.should be_completed
  end

end

describe TasksController, 'DELETE cancelled task' do
  it_should_behave_like 'TasksController DELETE task'

  before(:each) { @task.status = :cancelled ; @task.save! }

  it 'should 404 if not associated with task' do
    authenticate person('unknown')
    delete :destroy, :id=>@task.id
    response.should be_not_found
    Task.should have(1).record
  end

  it 'should 404 if associated with task' do
    authenticate @admin
    delete :destroy, :id=>@task.id
    response.should be_not_found
    Task.should have(1).record
  end

end


describe TasksController, 'POST task', :shared=>true do
  before :each do
    @admin, @owner = people('admin', 'owner')
    @task = Task.create!(defaults(:admins=>@admin, :owner=>@owner))
    controller.use_rails_error_handling!
  end
  
  it 'should map to /tasks/{id}' do
    route_for(:controller=>'tasks', :action=>'complete', :id=>@task.id).should eql("/tasks/#{@task.id}")
    lambda { route_for(:controller=>'tasks', :action=>'complete') }.should raise_error(ActionController::RoutingError)
  end

  it 'should map to /tasks/{id}.{format}' do
    route_for(:controller=>'tasks', :action=>'complete', :id=>@task.id, :format=>'xml').should eql("/tasks/#{@task.id}.xml")
  end

end

describe TasksController, 'POST reserved task' do
  before :each do
    @admin = person('admin')
    @task = Task.reserve!(@admin)
    controller.use_rails_error_handling!
  end

  it 'should 404' do
    authenticate @admin
    post :complete, :id=>@task.id
    response.should be_not_found
    Task.should have(1).record
  end

end

describe TasksController, 'POST active task' do
  it_should_behave_like 'TasksController POST task'

  before(:each) { authenticate @owner }

  it 'should 404 if not associated with task' do
    authenticate person('unknown')
    post :complete, :id=>@task.id
    response.should be_not_found
    @task.reload.should be_active
  end

  it 'should 403 if not task owner' do
    authenticate @admin
    post :complete, :id=>@task.id
    response.should be_forbidden
    @task.reload.should be_active
  end

  it 'should 200 if task completed' do
    post :complete, :id=>@task.id
    response.should be_ok
  end

  it 'should change task status to completed' do
    post :complete, :id=>@task.id
    @task.reload.should be_completed
  end

  it 'should leave task data intact if no data provided' do
    data = { 'foo'=>'cow', 'bar'=>'bell' }
    @task.update_attributes! :data=>data
    post :complete, :id=>@task.id
    @task.reload.data.should == data
  end

  it 'should change task data if new data provided' do
    @task.update_attributes! :data=>{ 'foo'=>'cow', 'bar'=>'bell' }
    data = { 'foo'=>'more' }
    post :complete, :id=>@task.id, :task=>{ :data=>data }
    @task.reload.data.should == data
  end

end

describe TasksController, 'POST suspended task' do
  it_should_behave_like 'TasksController POST task'

  before(:each) { @task.status = :suspended ; @task.save! }

  it 'should 403' do
    authenticate @owner
    post :complete, :id=>@task.id
    response.should be_forbidden
  end

end

describe TasksController, 'POST completed task' do
  it_should_behave_like 'TasksController POST task'

  before(:each) { @task.status = :completed ; @task.save! }

  it 'should 409' do
    authenticate @owner
    post :complete, :id=>@task.id
    response.should be_conflict
  end

end

describe TasksController, 'POST unclaimed task' do
  it_should_behave_like 'TasksController POST task'

  before(:each) { @task.owner = nil ; @task.save! }

  it 'should 403' do
    authenticate @admin
    post :complete, :id=>@task.id
    response.should be_forbidden
  end

end

describe TasksController, 'POST cancelled task' do
  it_should_behave_like 'TasksController POST task'

  before(:each) { @task.status = :cancelled ; @task.save! }

  it 'should 404' do
    authenticate @owner
    post :complete, :id=>@task.id
    response.should be_not_found
    @task.reload.should be_cancelled
  end

end



describe TasksController, 'token authentication' do
  before :each do
    @task = Task.create(defaults(:owner=>person('owner'), :potential_owners=>person('excluded'),
                                                         :excluded_owners=>person('excluded')))
  end

  def authenticate(person)
    credentials = ['_token', @task.token_for(person)]
    request.headers['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(*credentials)
  end

  it 'should be used if provided' do
    authenticate person('owner')
    get :show, :id=>@task.id
    response.should be_ok
  end

  it 'should authenticate stakeholder' do
    authenticate person('owner')
    get :show, :id=>@task.id
    response.should be_ok
    assigns[:authenticated] == person('owner')
  end

  it 'should 404 if not stakeholder' do
    authenticate person('noone')
    lambda { get :show, :id=>@task.id }.should raise_error(ActiveRecord::RecordNotFound)
  end

  it 'should 404 if excluded owner' do
    authenticate person('excluded')
    lambda { get :show, :id=>@task.id }.should raise_error(ActiveRecord::RecordNotFound)
  end

  it 'should 404 if no such task' do
    authenticate person('owner')
    lambda { get :show, :id=>@task.id + 1 }.should raise_error(ActiveRecord::RecordNotFound)
  end

  it 'should 404 if task cancelled' do
    @task.status = :cancelled ; @task.save!
    authenticate person('owner')
    lambda { get :show, :id=>@task.id }.should raise_error(ActiveRecord::RecordNotFound)
  end
  
end
=end
