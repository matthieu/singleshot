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

  should_route :get, '/tasks', :controller=>'tasks', :action=>'index'
  should_route :post, '/tasks', :controller=>'tasks', :action=>'create'
  should_route :get, '/tasks/1', :controller=>'tasks', :action=>'show', :id=>'1'
  should_route :put, '/tasks/1', :controller=>'tasks', :action=>'update', :id=>'1'


  describe 'GET /tasks' do
    before do
      Task.make :title=>'expenses' 
      Task.make :title=>'TPS report'
    end

    describe '.html' do
      before { request.accept = Mime::HTML }

      it('should require authentication') { get :index ; should redirect_to(session_url) }
      it('should render tasks')           { authenticate Person.creator ; get :index ; should render_template('tasks/index.html.erb') }
      it('should render tasks for authenticated person')  { rendering.proxy_owner.should == Person.creator }
      it('should render pending tasks')                   { rendering.proxy_scope.proxy_options.should == Task.pending.proxy_options }
      it('should load tasks with stakeholders')           { rendering.proxy_options.should == Task.with_stakeholders.proxy_options }
    end

    describe '.json' do
      before { request.accept = Mime::JSON }

      it('should require authentication') { get :index ; should respond_with(401) }
      it('should render tasks')           { authenticate Person.creator ; get :index ; json.should include('task_list') }
      it('should render tasks for authenticated person')  { rendering.proxy_owner.should == Person.creator }
      it('should render pending tasks')                   { rendering.proxy_scope.proxy_options.should == Task.pending.proxy_options }
      it('should load tasks with stakeholders')           { rendering.proxy_options.should == Task.with_stakeholders.proxy_options }
    end

    describe '.xml' do
      before { request.accept = Mime::XML }

      it('should require authentication') { get :index ; should respond_with(401) }
      it('should render tasks')           { authenticate Person.creator ; get :index ; xml.should include('task_list') }
      it('should render tasks for authenticated person')  { rendering.proxy_owner.should == Person.creator }
      it('should render pending tasks')                   { rendering.proxy_scope.proxy_options.should == Task.pending.proxy_options }
      it('should load tasks with stakeholders')           { rendering.proxy_options.should == Task.with_stakeholders.proxy_options }
    end

    describe '.atom'
    describe '.ical'

    def rendering
      controller.should_receive(:presenting) { |sym, tasks| @rendering = tasks }
      authenticate Person.creator
      get :index
      @rendering
    end
  end


  describe 'POST /tasks' do
    before { rescue_action_in_public! }
    before { authenticate Person.creator }
    before { @params = { 'task'=>{ 'title'=>'expenses' } } }

    describe '.html' do
      before { request.accept = Mime::HTML }

      it('should require authentication')               { authenticate nil ; post :create, @params ; should redirect_to(session_url) }
      it('should verify parameters include task')       { post :create, nil ; should respond_with(400) }
      it('should require task to have a title')         { post :create, 'task'=>{} ; should respond_with(422) }
      it('should redirect back to task list')           { post :create, @params ; should redirect_to(tasks_url) }
    end

    describe '.json' do
      before { request.accept = Mime::JSON }

      it('should require authentication')               { authenticate nil ; post :create, @params ; should respond_with(401) }
      it('should verify parameters include task')       { post :create, nil ; should respond_with(400) }
      it('should require task to have a title')         { post :create, 'task'=>{} ; should respond_with(422) }
      it('should return status 201 Created')            { post :create, @params ; should respond_with(201) }
      it('should return location of new task')          { post :create, @params ; response.location.should == task_url(Task.last) }
      it('should render new task')                      { post :create, @params ; json.should include('task') }
    end

    describe '.xml' do
      before { request.accept = Mime::XML }

      it('should require authentication')               { authenticate nil ; post :create, @params ; should respond_with(401) }
      it('should verify parameters include task')       { post :create, nil ; should respond_with(400) }
      it('should require task to have a title')         { post :create, 'task'=>{} ; should respond_with(422) }
      it('should return status 201 Created')            { post :create, @params ; should respond_with(201) }
      it('should return location of new task')          { post :create, @params ; response.location.should == task_url(Task.last) }
      it('should render new task')                      { post :create, @params ; xml.should include('task') }
    end

    it('should create new task from request entity')          { new_task!.title.should == 'expenses' }
    it('should set task creator to authenticated person')     { new_task!.in_role('creator').first.should == Person.creator }
    it('should set task supervisor to authenticated person')  { new_task!.in_role('supervisor').first.should == Person.creator }
    it('should accept stakeholders as role/name pairs')       { new_task!('stakeholders'=>[{'role'=>'owner', 'person'=>Person.owner.to_param}])
                                                                Task.last.owner.should == Person.owner }

    def new_task!(attributes = {})
      attributes['title'] ||= 'expenses'
      request.accept = Mime::HTML
      post :create, 'task'=>attributes
      fail response.status unless response.code =~ /(200|201|303)/
      Task.last
    end
  end


  describe 'GET /tasks/{id}' do
    before { rescue_action_in_public! }
    before do
      @task = Task.make(:title=>'expenses')
      @params = { 'id'=>@task.id }
    end

    describe '.html' do
      before { request.accept = Mime::HTML }

      it('should require authentication')     { get :show, @params ; should redirect_to(session_url) }
      it('should reject unauthorized access') { authenticate Person.other ; get :show, @params ; should respond_with(404) }
      it('should render task')                { authenticate Person.creator ; get :show, @params ; should render_template('tasks/show.html.erb') }
    end

    describe '.json' do
      before { request.accept = Mime::JSON }

      it('should require authentication')     { get :show, @params ; should respond_with(401) }
      it('should reject unauthorized access') { authenticate Person.other ; get :show, @params ; should respond_with(404) }
      it('should render task')                { authenticate Person.creator ; get :show, @params ; json['task']['title'].should == 'expenses' }
    end

    describe '.xml' do
      before { request.accept = Mime::XML }

      it('should require authentication')     { get :show, @params ; should respond_with(401) }
      it('should reject unauthorized access') { authenticate Person.other ; get :show, @params ; should respond_with(404) }
      it('should render task')                { authenticate Person.creator ; get :show, @params ; xml['task']['title'].should == 'expenses' }
    end

  end


  describe 'PUT /tasks/{id}' do
    before { rescue_action_in_public! }
    before do
      @task = Task.make(:title=>'expenses')
      @params = { 'id'=>@task.id, 'task'=>{ 'priority' => 1 } }
    end
    before { authenticate Person.supervisor }

    describe '.html' do
      before { request.accept = Mime::HTML }

      it('should require authentication')         { authenticate nil ; put :update, @params ; should redirect_to(session_url) }
      it('should reject unauthorized access')     { authenticate Person.other ; put :update, @params ; should respond_with(404) }
      it('should verify parameters include task') { put :update, 'id'=>@task.id ; should respond_with(400) }
      it('should redirect back to task list')     { put :update, @params ; should redirect_to(back) }
    end

    describe '.json' do
      before { request.accept = Mime::JSON }

      it('should require authentication')         { authenticate nil ;put :update, @params ; should respond_with(401) }
      it('should reject unauthorized access')     { authenticate Person.other ; put :update, @params ; should respond_with(404) }
      it('should verify parameters include task') { put :update, 'id'=>@task.id ; should respond_with(400) }
      it('should render task')                    { put :update, @params ; json['task']['title'].should == 'expenses' }
    end

    describe '.xml' do
      before { request.accept = Mime::XML }

      it('should require authentication')         { authenticate nil ; put :update, @params ; should respond_with(401) }
      it('should reject unauthorized access')     { authenticate Person.other ; put :update, @params ; should respond_with(404) }
      it('should verify parameters include task') { put :update, 'id'=>@task.id ; should respond_with(400) }
      it('should render task')                    { put :update, @params ; xml['task']['title'].should == 'expenses' }
    end

    it 'should modify task' do
      lambda { put :update, @params }.should change { Task.find(@task).priority }.to(1)
    end
    it 'should accept stakeholders as role/name pairs' do
      lambda { put :update, 'id'=>@task.id, 'task'=>{ 'stakeholders'=>[{ 'role'=>'observer', 'person'=>'other' }] } }.
        should change { Task.last.in_role('observer') }.to([Person.other])
    end
  end

end
