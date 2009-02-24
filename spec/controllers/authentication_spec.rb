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


class AuthenticationController < ApplicationController

  def index
    render :nothing=>true
  end

  def feed
    render :nothing=>true
  end
end


describe AuthenticationController do
  controller_name :authentication
  before { controller.use_rails_error_handling! }
  before { @person = Person.make(:email=>'me@example.com', :locale=>:tlh, :timezone=>-11) }

  describe 'unauthenticated' do
    before { get :index }

    it { should redirect_to(session_url) }
    it('should store request URL in session')  { session[:return_url].should == request.url }
    it('should reset I18n locale')             { I18n.locale.should == :en }
    it('should reset TimeZone')                { Time.zone.utc_offset == 0 }
  end

  describe 'unauthenticated XML' do
    before { get :index, :format=>:xml }
    it { should respond_with(401) }
  end

  describe 'unauthenticated JSON' do
    before { get :index, :format=>:json }
    it { should respond_with(401) }
  end

  describe 'with invalid session' do
    before { get :index, nil, :authenticated=>0 }
    it { should redirect_to(session_url) }
  end

  describe 'with authenticated session' do
    before { get :index, nil, :authenticated=>@person.id }
    it { should respond_with(200) }
    it { should accept_authenticated_user }
    it('should set I18n locale')               { I18n.locale.should == :tlh }
    it('should set TimeZone')                  { Time.zone.should == ActiveSupport::TimeZone[-11] }
  end

  describe 'with HTTP Basic' do
    before { request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('me', 'secret') }
    before { get :index }

    it { should respond_with(200) }
    it { should accept_authenticated_user }
  end

  describe 'with HTTP Basic but wrong credentials' do
    before { request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('me', 'wrong') }
    before { get :index }

    it { should respond_with(401) }
  end

  describe 'with access key' do
    describe 'Atom' do
      before { get :feed, :access_key=>@person.access_key, :format=>:atom }
      it { should respond_with(200) }
      it { should accept_authenticated_user }
    end

    describe 'iCal' do
      before { get :feed, :access_key=>@person.access_key, :format=>:ics }
      it { should respond_with(200) }
      it { should accept_authenticated_user }
    end

    describe 'HTML' do
      before { get :feed, :access_key=>@person.access_key, :format=>:html }
      it { should redirect_to(session_url) }
    end

    describe 'POST method' do
      before { post :feed, :access_key=>'wrong', :format=>:atom }
      it { should respond_with(405) }
    end

  end

  describe 'with wrong access key' do
    before { get :feed, :access_key=>'wrong', :format=>:atom }
    it { should respond_with(403) }
  end

  def accept_authenticated_user
    simple_matcher "accept authenticated user" do |given|
      controller.send(:authenticated) == @person
    end
  end
  
end
