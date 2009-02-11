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
  before { @person = Person.named('me') }

  describe 'unauthenticated' do
    before { get :index }

    it { should redirect_to(session_url) }
    it('should store request URL in session')  { session[:return_url].should == request.url }
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
    before { get :index, nil, :person_id=>0 }
    it { should redirect_to session_url }
  end

  describe 'with authenticated session' do
    before { get :index, nil, :person_id=>@person.id }
    it { should respond_with(200) }
    it { should accept_authenticated_user }
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
