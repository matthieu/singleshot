class TaskForController < ApplicationController

  before_filter :authenticate
  verify :params=>'task', :only=>:update

  def show
    respond_to do |wants|
      wants.xml { render :xml=>@task }
      wants.json { render :json=>@task }
    end
  end

  def update
    @task.modify_by(@person).update_attributes! params[:task]
    respond_to do |wants|
      wants.xml { render :xml=>@task }
      wants.json { render :json=>@task }
    end
  end

private

  def authenticate
    @task = Task.with_stakeholders.find(params[:task_id])
    @person = Person.identify(params[:person_id])
    authenticate_or_request_with_http_basic request.domain do |login, token|
      login == '_token' && token == @task.token_for(@person)
    end
  end

end
