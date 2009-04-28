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


describe TemplatesController do

  should_route :post, '/templates', :controller=>'templates', :action=>'create'
  describe :post=>'create' do
    before { authenticate Person.supervisor }
    params 'template'=>{ 'title'=>'TPS Report', 'potential_owners'=>[Person.potential.to_param] }

    share_examples_for 'template.create' do
      it('should create new template')        { new_template.title.should == 'TPS Report' }
      it('should assign template creator')    { new_template.creator.should == Person.supervisor }
      it('should assign supervisor')          { new_template.supervisors.should == [Person.supervisor] }
      it('should assign potential owners')    { new_template.potential_owners.should == [Person.potential] }
      should_assign_to(:instance)             { Template.last }

      describe '(no title)' do
        params 'template'=>{}
        should_respond_with 422
      end

      def new_template
        run_action!
        Template.count.should == 1
        Template.last
      end
    end

    describe Mime::HTML do
      it_should_behave_like 'template.create'
      should_redirect_to { templates_url }

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_redirect_to { session_url }
      end

    end

    describe Mime::JSON do
      params 'template'=>{ 'title'=>'TPS Report', 'potential_owners'=>[Person.potential.to_param] }
      it_should_behave_like 'template.create'
      should_respond_with_created { template_url(Template.last) }
      should_respond_with_content_type Mime::JSON
      it('should render template object') { json.should include('template') }

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_respond_with 401
      end
    end

    describe Mime::XML do
      it_should_behave_like 'template.create'
      should_respond_with_created { template_url(Template.last) }
      should_respond_with_content_type Mime::XML
      it('should render template element') { xml.should include('template') }

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_respond_with 401
      end
    end

  end


  should_route :get, '/templates/55', :controller=>'templates', :action=>'show', :id=>55
  describe :get=>'show', :id=>55 do
    before { @template = Template.make(:id=>55, :title=>'TPS Report') }
    before { authenticate Person.owner }

    should_assign_to(:instance) { @template }
    should_render_template 'templates/show.html.erb'

    describe '(without form)' do
      should_not_assign_to :iframe_url
    end

    describe '(with form URL)' do
      before { @template.create_form :url=>'http://localhost/form' }
      before { @template.update_attributes! :form=>{ :url=>'http://localhost/form' } }
      should_assign_to :iframe_url, :with=>'http://localhost/form'
    end

    describe '(with form)' do
      before { @template.update_attributes! :form=>{ :html=>'<input>' } }
      should_assign_to(:iframe_url) { form_url(55) }
    end

    describe '(unauthenticated)' do
      before { authenticate nil }
      should_redirect_to { session_url }
    end

    describe '(inaccessible)' do
      before { authenticate Person.other }
      should_respond_with 404
    end

  end


  should_route :put, '/templates/56', :controller=>'templates', :action=>'update', :id=>56
  describe :put=>'update' do
    before { Template.make :id=>56, :title=>'TPS Report' }
    before { authenticate Person.supervisor }
    params :id=>56, :template=>{ :priority=>1 }

    share_examples_for 'template.update' do
      it("should update template") { run_action! ; Template.last.priority.should == 1 }

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
      it_should_behave_like 'template.update'
      should_redirect_to { template_url(56) }

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_redirect_to { session_url }
      end
    end

    describe Mime::JSON do
      it_should_behave_like 'template.update'
      should_respond_with 200

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_respond_with 401
      end
    end

    describe Mime::XML do
      it_should_behave_like 'template.update'
      should_respond_with 200

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_respond_with 401
      end
    end

  end


  should_route :delete, '/templates/56', :controller=>'templates', :action=>'destroy', :id=>56
  describe :delete=>'destroy' do
    before { Template.make :id=>56, :title=>'TPS Report' }
    before { authenticate Person.supervisor }
    params :id=>56

    share_examples_for 'template.destroy' do
      it("should delete template") { run_action! ; Template.all.should be_empty }

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
      it_should_behave_like 'template.destroy'
      should_redirect_to { templates_url }

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_redirect_to { session_url }
      end
    end

    describe Mime::JSON do
      it_should_behave_like 'template.destroy'
      should_respond_with 200

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_respond_with 401
      end
    end

    describe Mime::XML do
      it_should_behave_like 'template.destroy'
      should_respond_with 200

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_respond_with 401
      end
    end

  end
end
