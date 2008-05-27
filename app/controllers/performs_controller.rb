class PerformsController < ApplicationController

  def show
    respond_to do |wants|
      wants.xml { render :xml=>@task }
      wants.json { render :json=>@task }
    end
  end

private

  def authenticate
    @task = Task.visible.find(params['task_id'])
    authenticate_or_request_with_http_basic request.domain do |login, token|
      login == '_token' && @authenticated = @task.authenticate(token)
    end
  end

end
