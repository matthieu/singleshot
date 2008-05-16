require File.dirname(__FILE__) + '/../spec_helper'


describe SessionsController do

  it 'should route show/create/destroy actions to same URL' do
    route_for(:controller =>'sessions', :action=>'show').should eql('/session')
  end

end


describe SessionsController, 'GET' do

  it 'should render login page' do
    get :show
    response.should be_ok
    response.should render_template('sessions/show')
  end

end


describe SessionsController, 'POST' do

  include Specs::Authentication

  before :all do
    @credentials = { :login=>'assaf', :password=>'secret' }
    @person = person(@credentials[:login])
  end

  it 'should redirect to login page with no error if login is empty' do
    post :create
    response.should redirect_to(session_url)
    flash[:error].should be_blank
    session[:person_id].should be_nil
  end

  it 'should redirect to login page with error, if login/password do not match' do
    post :create, @credentials.merge(:password=>'wrong')
    response.should redirect_to(session_url)
    flash[:error].should match(/no account/i)
    session[:person_id].should be_nil
  end

  it 'should establish new session if authenticated' do
    post :create, @credentials
    flash[:error].should be_nil
    session[:person_id].should eql(@person.id)
  end

  it 'should redirect to root_url if authenticated' do
    post :create, @credentials
    response.should redirect_to(root_url)
  end

  it 'should redirect to flash[:return_to] if specified' do
    post :create, @credentials, nil, { :return_to=>'http://foo' }
    response.should redirect_to('http://foo')
  end

end


describe SessionsController, 'DELETE' do

  before :each do
    session[:person_id] = 1
  end

  it 'should destroy session' do
    delete :destroy
    session[:person_id].should be_nil
  end

  it 'should redirect to root URL' do
    delete :destroy
    response.should redirect_to(root_url)
  end

end
