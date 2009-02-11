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


describe SessionsController do
  controller_name :sessions

  it { should route('/session', :controller =>'sessions', :action=>'show') }

  describe 'get /' do
    before { get :show }

    it { should render(:template=>'sessions/show') }
  end


  describe 'post /' do
    before { @person = Person.named('me') }

    describe 'authenticated' do
      before { post :create, :login=>@person.identity, :password=>'secret' }

      it { should redirect_to(root_url) }
      it('should store authenticated user in session')  { session[:person_id].should == @person.id }
      it('should clear flash')                          { flash.should be_empty }
    end

    describe 'authenticated with return_url' do
      before { post :create, { :login=>@person.identity, :password=>'secret' }, { :return_url=>'http://return_url' } }

      it { should redirect_to('http://return_url') }
      it('should clear return_url from session')         { session[:return_url].should be_nil }
    end

    describe 'no credentials' do
      before { post :create }

      it { should redirect_to(session_url) }
      it('should have no authencited user in session')  { session[:person_id].should be_nil }
    end

    describe 'wrong credentials' do
      before { post :create, :login=>@person.identity, :password=>'wrong' }

      it { should redirect_to(session_url) }
      it('should have no authencited user in session')  { session[:person_id].should be_nil }
      it('should have error message in flash')          { flash[:error].should match(/no account/i) }
    end
  end

  describe 'delete /' do
    before { authenticate }
    before { delete :destroy }

    it('should clear session') { session.should be_empty }
    it { should redirect_to(root_url) }
  end

end
