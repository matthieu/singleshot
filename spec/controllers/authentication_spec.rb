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


class AuthenticationTestController < ApplicationController
  self.allow_forgery_protection    = true

  def index
    render :nothing=>true
  end

  def feed
    render :nothing=>true
  end
end

describe AuthenticationTestController do
  before { @person = Person.make(:email=>'me@example.com', :locale=>'tlh', :timezone=>-11) }

  describe 'unauthenticated request' do
    describe '(HTML)' do
      before { get :index }
      it('should redirect to login page')         { should redirect_to(session_url) }
      it('should store return URL in session')    { session[:return_url].should == request.url }
      it('should reset I18n locale')              { I18n.locale.should == :en }
      it('should reset TimeZone')                 { Time.zone.utc_offset == 0 }
    end

    describe '(XML)' do
      before { get :index, :format=>:xml }
      it { should respond_with(401) }
    end

    describe '(JSON)' do
      before { get :index, :format=>:json }
      it { should respond_with(401) }
    end

    describe '(Atom)' do
      before { get :index, :format=>:atom }
      it { should respond_with(401) }
    end
  end

  describe 'session authentication' do
    describe '(invalid session)' do
      before { get :index, nil, :authenticated=>'foo' }
      it('should redirect to login page')           { should redirect_to(session_url) }
    end

    describe '(authenticated)' do
      before { get :index, nil, :authenticated=>@person.id }
      it { should respond_with(200) }
      it('should return authentication account')    { controller.send(:authenticated) == @person }
      it('should set I18n.locale')                  { I18n.locale.should == :tlh }
      it('should set Time.zone')                    { Time.zone.should == ActiveSupport::TimeZone[-11] }
    end
  end

  describe 'HTTP Basic authentication' do

    describe '(with credentials)' do
      before do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@person.username, 'secret')
        get :index
      end

      it { should respond_with(200) }
      it('should authenticate account')           { controller.send(:authenticated) == @person }
    end

    describe '(with invalid credentials)' do
      before do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@person.username, 'wrong')
        get :index
      end

      it { should respond_with(401) }
    end

    describe '(POST)' do
      before do
ActionController::Base.allow_forgery_protection    = true
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@person.username, 'secret')
        request.env['CONTENT_TYPE'] = Mime::URL_ENCODED_FORM.to_s
        post :update, :format=>:html
      end
    end
  end

  describe 'access key authentication' do
    before { rescue_action_in_public! }

    describe '(Atom)' do
      before { get :feed, :access_key=>@person.access_key, :format=>:atom }
      it { should respond_with(200) }
      it('should authenticate account')           { controller.send(:authenticated) == @person }
    end

    describe '(iCal)' do
      before { get :feed, :access_key=>@person.access_key, :format=>:ics }
      it { should respond_with(200) }
      it('should authenticate account')           { controller.send(:authenticated) == @person }
    end

    describe '(HTML)' do
      before { get :feed, :access_key=>@person.access_key, :format=>:html }
      it('should redirect to login page')         { should redirect_to(session_url) }
    end

    describe '(POST)' do
      before { post :feed, :access_key=>'wrong', :format=>:atom }
      it { should respond_with(405) }
    end

    describe '(invalid access key)' do
      before { get :feed, :access_key=>'wrong', :format=>:atom }
      it { should respond_with(403) }
    end
  end

  describe 'forgery protection' do
    before { rescue_action_in_public! }
    before { request.env['CONTENT_TYPE'] = Mime::URL_ENCODED_FORM.to_s }
    it 'should apply when using session authentication' do
      post :index, nil, :authenticated=>@person.id
      should respond_with(422)
    end
    it 'should not apply when using HTTP Basic authentication' do
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@person.username, 'secret')
      post :index
      should respond_with(200)
    end
  end

end
