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
    it ('should return location of new task')     { post(:create, @params.merge(:format=>:json), as_creator).should respond_with('Location'=>task_url(controller.send(:task))) }
    it ('should redirect to new task (HTML)')     { post(:create, @params.merge(:format=>:html), as_creator).should redirect_to(task_url(controller.send(:task))) }
    it ('should render new task (JSON)')          { parse(:json, post(:create, @params.merge(:format=>:json), as_creator))['task']['title'].should == 'expenses' }
    it ('should render new task (XML)')           { parse(:xml, post(:create, @params.merge(:format=>:xml), as_creator))['task']['title'].should == 'expenses' }
    it ('should accept stakeholders as role/name pairs') { new_task!(:stakeholders=>[{'role'=>'owner', 'person'=>Person.owner.to_param}]).owner.should == Person.owner }

    def new_task!(attributes = nil)
      params = @params.merge(:format=>:html)
      params[:task].update attributes if attributes
      post :create, params, as_creator
      fail response.status unless response.code =~ /(200|201|303)/
      controller.send(:task)
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
    before { @stakeholders = [{ 'role'=>'supervisor', 'person'=>'supervisor' }] }
    before { @params = { :id=>@task.id, :task=>{ 'priority'=>1, 'stakeholders'=>@stakeholders } } }

    it { should route(:put, '/tasks/1', :controller=>'tasks', :action=>'update', :id=>'1') }
    it ('should require authentication (HTML)')   { put(:update, @params).should redirect_to(session_url) }
    it ('should require authentication (JSON)')   { put(:update, @params.merge(:format=>:json)).should respond_with(401) }
    it ('should reject unauthorized requests')    { put(:update, @params.merge(:format=>:json), as_creator).should respond_with(422) }
    it ('should verify parameters include task')  { put(:update, @params.except(:task), as_supervisor).should respond_with(400) }
    it ('should redirect back to task (HTML)')    { put(:update, @params.merge(:format=>:html), as_supervisor).should redirect_to(task_url(@task)) }
    it ('should render task (JSON)')              { parse(:json, put(:update, @params.merge(:format=>:json), as_supervisor)).should include('task') }
    it ('should render task (XML)')               { parse(:xml, put(:update, @params.merge(:format=>:xml), as_supervisor)).should include('task') }
    it ('should modify task')                     { lambda { put(:update, @params, as_supervisor) }.should change { Task.find(@task).priority }.to(1) }
    it ('should accept stakeholders as role/name pairs') do
      parse(put(:update, @params.merge(:format=>:json), as_supervisor))['task']['stakeholders'].should == @stakeholders
    end
    # Can change stakeholders, except past owner

  end


  describe 'index' do
    before { @tasks = [Task.make(:title=>'expenses'), Task.make(:title=>'tps report')] }

    it { should route(:get, '/tasks', :controller=>'tasks', :action=>'index') }
    it ('should require authentication (HTML)')   { get(:index).should redirect_to(session_url) }
    it ('should require authentication (JSON)')   { get(:index, :format=>:json).should respond_with(401) }
    it ('should render tasks (HTML)')             { get(:index, { :format=>:html }, as_creator).should respond_with('tasks/index.html.erb') }
    it ('should render tasks (JSON)')             { parse(:json, get(:index, { :format=>:json }, as_creator)).should include('task_list') }
    it ('should render tasks (XML)')              { parse(:xml, get(:index, { :format=>:xml }, as_creator)).should include('task_list') }
    it  'should render tasks (Atom)'
    it  'should render tasks (iCal)'
    it ('should render tasks for authenticated person') { rendered.proxy_owner.should == Person.creator }
    it ('should render pending tasks')            { rendered.proxy_scope.proxy_options.should == Task.pending.proxy_options }
    it ('should load tasks with stakeholders')    { rendered.proxy_options.should == Task.with_stakeholders.proxy_options }
      
    def rendered
      unless @rendered
        controller.should_receive(:presenting) { |sym, tasks| @rendered = tasks }
        get :index, { :format=>:html }, as_creator
      end
      @rendered
    end
  end


  def parse(*args)
    response = args.pop
    response.content_type.should == args.shift.to_s if Symbol === args.first
    case response.content_type
    when Mime::JSON
      ActiveSupport::JSON.decode(response.body)
    when Mime::XML, Mime::ATOM
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
