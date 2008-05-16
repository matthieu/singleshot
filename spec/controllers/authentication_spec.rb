require File.dirname(__FILE__) + '/../spec_helper'

class AuthenticationTestController < ApplicationController
  prepend_before_filter :authenticate_with_access_key, :only=>['feed']

  def index
  end

  def feed
  end
end


share_examples_for 'AuthenticationTest' do
  controller_name :authentication_test

  before :all do
    @person = Person.create(:email=>'lucy@test.host', :password=>'secret')
  end

  after :all do
    Person.delete_all
  end
end


describe 'Unauthenticated request' do
  controller_name :authentication_test

  it 'should redirect to login page when requesting HTML' do
    get 'index'
    response.should redirect_to('/session')
  end

  it 'should pass request URL in return_to session parameter' do
    get 'index'
    flash[:return_to].should eql(controller.url_for(:controller=>'authentication_test', :action=>'index'))
  end

  it 'should return 401 when requesting XML document' do
    get 'index', :format=>'xml'
    response.should be(:unauthorized)
  end

  it 'should return 401 when requesting JSON document' do
    get 'index', :format=>'json'
    response.should be(:unauthorized)
  end
end


describe 'Session authentication' do
  it_should_behave_like 'AuthenticationTest'

  it 'should redirect to login page if person does not exist' do
    get 'index', nil, :person_id=>0
    response.should redirect_to('/session')
  end

  it 'should return response if user account exists' do
    get 'index', nil, :person_id=>@person.id
    response.should be(:ok)
  end

  it 'should assign authenticated user in controller' do
    get 'index', nil, :person_id=>@person.id
    assigns[:authenticated].should == @person
  end
end


describe 'Query param authentication' do
  it_should_behave_like 'AuthenticationTest'

  it 'should have no affect unless applied to action' do
    get 'index'
    response.should redirect_to('/session')
  end

  it 'should return 404 if not matching user\'s access key' do
    lambda { get 'feed', :access_key=>'wrong' }.should raise_error(ActiveRecord::RecordNotFound) 
  end

  it 'should return 404 if no access key provided' do
    lambda { get 'feed' }.should raise_error(ActiveRecord::RecordNotFound)
  end

  it 'should return 405 if POST request' do
    lambda { post 'feed', :access_key=>@person.access_key }.should raise_error(ActionController::MethodNotAllowed, /Only GET/)
  end

  it 'should return response if matching user\'s access key' do
    get 'feed', :access_key=>@person.access_key
    response.should be(:ok)
  end

  it 'should assign authenticated user in controller' do
    get 'feed', :access_key=>@person.access_key
    assigns[:authenticated].should == @person
  end
end


describe 'HTTP Basic username/password' do
  it_should_behave_like 'AuthenticationTest'

  it 'should return 401 if not authenticated' do
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('lucy', 'wrong')
    get 'index'
    response.should be(:unauthorized)
  end

  it 'should return response if authenticated' do
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('lucy', 'secret')
    get 'index'
    response.should be(:ok)
  end

  it 'should assign authenticated user in controller' do
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('lucy', 'secret')
    get 'index'
    assigns[:authenticated].should == @person
  end

  it 'should not fail on password-less account' do
    Person.create(:email=>'mary@test.host')
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('mary', 'wrong')
    get 'index'
    response.should be(:unauthorized)
  end
end
