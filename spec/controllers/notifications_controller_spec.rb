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


describe NotificationsController do

  # -- Show notifications --

  should_route :get, '/notifications', :controller=>'notifications', :action=>'index'
  describe :get=>'index' do
    before { authenticate Person.observer }
    before do
      2.times { Notification.make :recipients=>[Person.other] }
      @notifications = Array.new(3) { Notification.make }
    end


    describe Mime::HTML do
      should_assign_to(:copies) { Person.observer.notifications }
      should_render_template 'notifications/index'

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_redirect_to { session_url }
      end
    end

    describe Mime::JSON do
      should_assign_to(:copies) { Person.observer.notifications }
      should_respond_with 200
      should_respond_with_content_type Mime::JSON
      it('should render notifications object') { json.should include('notifications') }

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_respond_with 401
      end
    end

    describe Mime::XML do
      should_assign_to(:copies) { Person.observer.notifications }
      should_respond_with 200
      should_respond_with_content_type Mime::XML
      it('should render notifications element') { xml.should include('notifications') }

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_respond_with 401
      end
    end

  end


  # -- Create notification --

  should_route :post, '/notifications', :controller=>'notifications', :action=>'create'
  describe :post=>'create' do
    before { authenticate Person.creator }
    params 'notification'=>{ 'subject'=>'Completed', 'body'=>'TPS Report completed', 'recipients'=>[Person.observer.to_param] }

    share_examples_for 'notification.create' do
      it('should create new notification')      { new_notification.subject.should == 'Completed' }
      it('should assign notification creator')  { new_notification.creator.should == Person.creator }
      it('should assign recipients')            { new_notification.recipients.should == [Person.observer] }
      should_assign_to(:notification)           { new_notification }
      it('should e-mail recipients')            { run_action! ; ActionMailer::Base.deliveries.first.to.should == [Person.observer.email] }

      describe '(no subject)' do
        params 'notification'=>{}
        should_respond_with 422
      end

      def new_notification
        run_action!
        Notification.count.should == 1 and Notification.last
      end
    end

    describe Mime::HTML do
      it_should_behave_like 'notification.create'
      should_redirect_to { notifications_url }

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_redirect_to { session_url }
      end

    end

    describe Mime::JSON do
      it_should_behave_like 'notification.create'
      should_respond_with_created { notification_url(Notification.last) }
      should_respond_with_content_type Mime::JSON
      it('should render notification object') { json.should include('notification') }

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_respond_with 401
      end
    end

    describe Mime::XML do
      it_should_behave_like 'notification.create'
      should_respond_with_created { notification_url(Notification.last) }
      should_respond_with_content_type Mime::XML
      it('should render notification element') { xml.should include('notification') }

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_respond_with 401
      end
    end

  end


  # -- View notification --

  should_route :get, '/notifications/93', :controller=>'notifications', :action=>'show', :id=>93
  describe :get=>'show' do
    before { Notification.make :id=>93, :recipients=>[Person.observer] }
    before { authenticate Person.observer }
    params 'id'=>93

    share_examples_for 'notification.show' do
      should_assign_to(:copy) { Notification::Copy.last }

      describe '(inaccessible)' do
        before { authenticate Person.other }
        should_respond_with 404
      end
    end

    describe Mime::HTML do
      it_should_behave_like 'notification.show'
      it('should mark notification as read') { run_action! ; Notification::Copy.last.should be_read }
      should_render_template 'notifications/show.html.erb'

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_redirect_to { session_url }
      end
    end

    describe Mime::JSON do
      it_should_behave_like 'notification.show'
      should_respond_with_content_type Mime::JSON
      it('should render notification object') { json.should include('notification') }

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_respond_with 401
      end
    end

    describe Mime::XML do
      it_should_behave_like 'notification.show'
      should_respond_with_content_type Mime::XML
      it('should render notification element') { xml.should include('notification') }

      describe '(unauthenticated)' do
        before { authenticate nil }
        should_respond_with 401
      end
    end
  end


  # -- Mark notification as read --

  should_route :put, '/notifications/93', :controller=>'notifications', :action=>'update', :id=>93
  describe :put=>'update' do
    before { Notification.make :id=>91 ; Notification.make :id=>92 }
    before { Notification.make :id=>93, :recipients=>[Person.observer] }
    before { authenticate Person.observer }
    params 'id'=>93, 'read'=>'true'

    describe '(marked read)' do
      it('should mark notification as read') { run_action! ; Notification::Copy.last.should be_read }
      should_respond_with 200
      should_respond_with_body "2"
    end

    describe '(inaccessible)' do
      before { authenticate Person.other }
      should_respond_with 404
    end
  end

end
