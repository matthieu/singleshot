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


describe SessionsController do
  controller_name :sessions

  it { should route(:get, '/session', :controller =>'sessions', :action=>'show') }
  it { should route(:post, '/session', :controller =>'sessions', :action=>'create') }
  it { should route(:delete, '/session', :controller =>'sessions', :action=>'destroy') }
  it { should filter_params(:password) }

  describe 'GET /session' do
    before { get :show }

    it { should render_template('sessions/show') }
  end

  describe 'POST /session' do
    before { @person = Person.named('me') }

    describe '(no credentials)' do
      before { post :create }

      it('should redirect back to /session')                  { should redirect_to(session_url) }
      it('should have no authenticated user in session')      { session[:authenticated].should be_nil }
    end

    describe '(wrong credentials)' do
      before { post :create, :username=>@person.identity, :password=>'wrong' }

      it('should redirect back to /session')                  { should redirect_to(session_url) }
      it('should have no authenticated user in session')      { session[:authenticated].should be_nil }
      it('should have error message in flash')                { flash[:error].should match(/no account/i) }
    end

    describe '(valid credentials)' do
      before { session[:older] = true }
      before { post :create, :username=>@person.identity, :password=>'secret' }

      it('should redirect to root url')                       { should redirect_to(root_url) }
      it('should store authenticated user in session')        { session[:authenticated].should == @person.id }
      it('should reset session to prevent session fixation')  { session[:older].should be_nil } 
      it('should clear flash')                                { flash.should be_empty }
    end

    describe '(valid credentials and return url)' do
      before { post :create, { :username=>@person.identity, :password=>'secret' }, { :return_url=>'http://return_url' } }

      it('should redirect to return url')                   { should redirect_to('http://return_url') }
      it('should clear return url from session')            { session[:return_url].should be_nil }
      it('should store authenticated user in session')      { session[:authenticated].should == @person.id }
    end

  end

  describe 'DELETE /session' do
    before do
      authenticate
      delete :destroy
    end

    it('should reset session')        { session.should be_empty }
    it('should redirect to root url') { should redirect_to(root_url) }
  end

end
