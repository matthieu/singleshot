class TaskForController < ApplicationController

  before_filter :authenticate
  verify :params=>'task', :only=>:update
  include TaskHelper

  def show
    respond_to do |wants|
      wants.xml { render :xml=>state.to_xml(:root=>'task') }
      wants.json { render :json=>state.to_json }
    end
  end

  def update
    @task.modify_by(@person).update_attributes! params[:task]
    show
  end

private

  def state
    attributes = { 'id'=>@task.id, 'url'=>task_url(@task), 'title'=>@task.title, 'description'=>@task.description,
      'status'=>@task.status, 'owner'=>@task.owner.to_param, 'data'=>@task.data }
    attributes.update 'update_url'=>task_for_person_url(@task, @person), 'redirect_url'=>complete_redirect_tasks_url if @task.owner?(@person)
    attributes
  end

  def authenticate
    @task = Task.with_stakeholders.find(params[:task_id])
    @person = Person.identify(params[:person_id])
    authenticate_or_request_with_http_basic request.domain do |login, token|
      login == '_token' && token == @task.token_for(@person)
    end
  end

end
