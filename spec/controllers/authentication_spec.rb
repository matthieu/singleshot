require File.dirname(__FILE__) + '/../spec_helper'

class AuthenticationTestController < ApplicationController

  def index
    render :nothing=>true
  end

  def feed
    render :nothing=>true
  end
end


describe 'Authentication' do
  controller_name :authentication_test
  
  before :all do
    @person = Person.create(:email=>'lucy@test.host', :password=>'secret')
  end
  
  describe 'Unauthenticated request' do
    it 'should redirect to login page when requesting HTML' do
      get 'index'
      response.should redirect_to('/session')
    end
    
    it 'should redirect to login page with request URL in return_to session value' do
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


  describe 'Session' do
    it 'should redirect to login page if person does not exist' do
      get 'index', nil, :person_id=>0
      response.should redirect_to('/session')
    end

    it 'should return response if user account exists' do
      get 'index', nil, :person_id=>@person.id
      response.should be(:ok)
    end

    it 'should assign authenticated user to controller' do
      get 'index', nil, :person_id=>@person.id
      assigns[:authenticated].should == @person
    end
  end


  describe 'HTTP Basic' do
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

    it 'should return 401 if not authenticated' do
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('lucy', 'wrong')
      get 'index'
      response.should be(:unauthorized)
    end

    it 'should not fail on password-less account' do
      Person.create(:email=>'mary@test.host')
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('mary', 'wrong')
      get 'index'
      response.should be(:unauthorized)
    end
  end


  describe 'Access key' do
    it 'should work when requesting Atom representation' do
      get 'feed', :access_key=>@person.access_key, :format=>Mime::ATOM
      response.should be(:ok)
    end
    
    it 'should work when requesting iCal representation' do
      get 'feed', :access_key=>@person.access_key, :format=>Mime::ICS
      response.should be(:ok)
    end
    
    it 'should not apply to content types other than Atom/iCal' do
      get 'feed', :access_key=>@person.access_key, :format=>Mime::HTML
      response.should redirect_to('/session')
    end
    
    it 'should return 403 if not matching user\'s access key' do
      get 'feed', 'access_key'=>'wrong', :format=>Mime::ATOM
      response.should be(:forbidden)
    end

    it 'should return 405 if POST request' do
      lambda { post 'feed', 'access_key'=>@person.access_key, :format=>Mime::ATOM }.
        should raise_error(ActionController::MethodNotAllowed, /Only GET/)
    end

    it 'should assign authenticated user in controller' do
      get 'feed', :access_key=>@person.access_key, :format=>Mime::ATOM
      assigns[:authenticated].should == @person
    end
  end


  after :all do
    Person.delete_all
  end
end
