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

  should_route :get, '/tasks', :controller=>'tasks', :action=>'index'
  describe :get=>'index' do
    before do
      Task.make :title=>'Absence request'
      Task.make :title=>'TPS report'
      Template.make :title=>'Expense report', :potential_owners=>[Person.owner]
      Template.make :title=>'Budget report'
    end
    before { authenticate Person.owner }

    share_examples_for 'task.index' do
      should_assign_to :tasks

      describe 'tasks' do
        subject { run_action! ; assigns[:tasks].scope(:find) }

        it('should include only visible tasks')         { subject[:conditions].should =~ /`stakeholders`.person_id = #{Person.owner.id}/ }
        it('should include active tasks')               { subject[:conditions].should =~ /tasks.status = 'active' AND involved.role = 'owner'/ }
        it('should include available tasks')            { subject[:conditions].should =~ /tasks.status = 'available' AND involved.role = 'potential_owner'/ }
        it('should eager load stakeholders and people') { subject[:include].should include(:stakeholders=>:person) }
      end
    end

    describe Mime::HTML do
      it_should_behave_like 'task.index'
      should_render_template 'tasks/index.html.erb'
      should_render_with_layout 'main'

      should_assign_to :activities
      should_assign_to :templates

      describe 'sidebar activities' do
        subject { run_action! ; assigns[:activities].scope(:find) }
        it('should include only last 7 days')           { subject[:conditions].should =~ /activities.created_at >= '#{Date.today - 7.days}'/ }
        it('should include only visible activities')    { subject[:conditions].should =~ /involved.person_id = #{Person.owner.id}/ }
        it('should include at most 5 activities')       { subject[:limit].should == 5 }
        it('should eager load people and tasks')        { subject[:include].should include(:person, :task) }
        it('should order from most recent to earliest') { subject[:order].should =~ /activities.created_at desc/ }
      end

      describe 'sidebar templates' do
        subject { run_action! ; assigns[:templates].scope(:find) }
        it('should include only visible activities')    { subject[:conditions].should =~ /`stakeholders`.person_id = #{Person.owner.id}/ }
      end

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_redirect_to { session_url }
      end
    end

    describe Mime::JSON do
      it_should_behave_like 'task.index'
      should_respond_with_content_type Mime::JSON
      it('should render task_list object') { json.should include('task_list') }

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_respond_with 401
      end
    end

    describe Mime::XML do
      it_should_behave_like 'task.index'
      should_respond_with_content_type Mime::XML
      it('should render task_list element') { xml.should include('task_list') }

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_respond_with 401
      end
    end

    describe Mime::ATOM do # TODO: describe /tasks.atom
    end
    describe Mime::ICS do  # TODO: describe /tasks.ics
    end

  end


  should_route :post, '/tasks', :controller=>'tasks', :action=>'create'
  describe :post=>'create' do
    before { authenticate Person.owner }
    params 'task'=>{ 'title'=>'TPS Report' }

    share_examples_for 'task.create' do
      should_assign_to(:instance) { Task.last }
      should_have_task 'TPS Report', 'creator'=>lambda { Person.owner }, 'owner'=>lambda { Person.owner },
                       'supervisors'=>lambda { [Person.owner] }

      describe '(no task title)' do
        params 'task'=>{}
        should_respond_with 422
      end
    end

    describe Mime::HTML do
      it_should_behave_like 'task.create'
      should_redirect_to { tasks_url }

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_redirect_to { session_url }
      end
    end

    describe Mime::JSON do
      it_should_behave_like 'task.create'
      should_respond_with_created { task_url(Task.last) }
      should_respond_with_content_type Mime::JSON
      it('should render task object') { json.should include('task') }

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_respond_with 401
      end
    end

    describe Mime::XML do
      it_should_behave_like 'task.create'
      should_respond_with_created { task_url(Task.last) }
      should_respond_with_content_type Mime::XML
      it('should render task element') { xml.should include('task') }

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_respond_with 401
      end
    end

  end


  should_route :get, '/tasks/1', :controller=>'tasks', :action=>'show', :id=>'1'
  describe :get=>'show', :id=>89 do
    before { @task = Task.make(:id=>89, :title=>'TPS Report') }
    before { authenticate Person.owner }

    share_examples_for 'task.show' do
      should_assign_to(:instance) { @task }

      describe '(inaccessible)' do
        before { authenticate Person.other }
        should_respond_with 404
      end
    end

    describe Mime::HTML do
      it_should_behave_like 'task.show'
      should_render_template 'tasks/show.html.erb'
      should_render_with_layout 'single'

      describe '(without form)' do
        should_not_assign_to :iframe_url
      end

      describe '(with form URL)' do
        before { @task.create_form :url=>'http://localhost/form' }
        before { @task.update_attributes! :form=>{ :url=>'http://localhost/form' } }
        should_assign_to :iframe_url, :with=>'http://localhost/form'
      end

      describe '(with form)' do
        before { @task.update_attributes! :form=>{ :html=>'<input>' } }
        should_assign_to(:iframe_url) { form_url(89) }
      end

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_redirect_to { session_url }
      end
    end

    describe Mime::JSON do
      it_should_behave_like 'task.show'
      should_respond_with_content_type Mime::JSON
      it('should render task object') { json.should include('task') }

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_respond_with 401
      end
    end

    describe Mime::XML do
      it_should_behave_like 'task.show'
      should_respond_with_content_type Mime::XML
      it('should render task element') { xml.should include('task') }

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_respond_with 401
      end
    end

  end


  should_route :put, '/tasks/1', :controller=>'tasks', :action=>'update', :id=>'1'
  describe :put=>'update', :id=>89 do
    before { @task = Task.make(:id=>89, :title=>'TPS Report') }
    before { authenticate Person.supervisor }
    params 'task'=>{ 'priority'=>1 }

    share_examples_for 'task.update' do
      should_assign_to(:instance) { @task }
      should_have_task 'TPS Report', :priority=>1

      describe '(inaccessible)' do
        before { authenticate Person.other }
        should_respond_with 404
      end

      describe '(unauthorized)' do
        before { authenticate Person.owner }
        should_respond_with 401
      end
    end

    describe Mime::HTML do
      it_should_behave_like 'task.update'
      # should_redirect_to 

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_redirect_to { session_url }
      end
    end

    describe Mime::JSON do
      it_should_behave_like 'task.update'
      should_respond_with_content_type Mime::JSON
      it('should render task object') { json.should include('task') }

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_respond_with 401
      end
    end

    describe Mime::XML do
      it_should_behave_like 'task.update'
      should_respond_with_content_type Mime::XML
      it('should render task element') { xml.should include('task') }

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_respond_with 401
      end
    end

  end


  # Expecting to have the titled task with the specified attributes. For example:
  #   should_have_task 'TPS Report'
  #   should_have_task 'TPS Report', :status=>'available'
  def have_task(*args)
    attrs = args.extract_options!
    title = attrs.delete('title') || args.shift
    with = attrs.inject({}) { |h, (k,v)| h.update(k=>v.respond_to?(:call) ? :proc : v) }
    simple_matcher "have task '#{title}' #{with.inspect}" do |given|
      run_action!
      task = Task.find_by_title(title)
      task && attrs.all? { |k,v| task.send(k) == v.respond_to?(:call) ? v.call : v }
    end
  end

end
