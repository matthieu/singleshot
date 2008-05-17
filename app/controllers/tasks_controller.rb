class TasksController < ApplicationController

  access_key_authentication :only=>[:index, :activity]

  verify :params=>:task, :only=>:update, :render=>{:text=>'Missing task', :status=>:bad_request}
  before_filter :authenticate, :except=>[:show, :update, :complete, :destroy]
  instance :task, :only=>[:show, :activity, :update, :complete, :destroy], :check=>:instance_accessible
  before_filter :forbid_reserved, :except=>[:update, :destroy]

  def index
    @alternate = { Mime::ATOM=>formatted_tasks_url(:format=>:atom, :access_key=>authenticated.access_key), 
                   Mime::ICS=>formatted_tasks_url(:format=>:ics, :access_key=>authenticated.access_key) }
    @tasks = Task.with_stakeholders.for_stakeholder(authenticated).pending.prioritized
  end

  def show
    @alternate = { Mime::ICS=>formatted_tasks_url(:format=>:ics, :access_key=>authenticated.access_key) }
    respond_to do |format|
      format.html do
        @activities = Activity.for_task(@task)
        render :layout=>'head'
      end
      format.xml  { render :xml=>@task }
      format.json { render :json=>@task }
      format.ics  do
        @tasks = [@task]
        #render :action=>'index'
      end
    end
  end

  def activity
    @title = "Activities &mdash; #{@task.title}"
    @alternate = { Mime::ATOM=>formatted_activity_task_url(@task, :atom, :access_key=>authenticated.access_key),
                   Mime::ICS=>formatted_activity_task_url(@task, :ics, :access_key=>authenticated.access_key) }
    @activities = Activity.for_task(@task)
    respond_to do |want|
      want.html do
        @days = @activities.group_by_day
        render :template=>'activities/show'
      end
      want.any { render :template=>'activities/show' }
    end
  end

  def new
    @task = Task.new(:creator=>authenticated)
    respond_to :html
  end

  def create
    if input = params[:task]
      input[:outcome_type] = suggested_outcome_type
      input[:admins] = Array(input[:admins]) + [authenticated]
      input.delete(:status)
      @task = Task.create!(input)
      respond_to do |format|
        format.html { redirect_to tasks_url }
        format.xml  { render :xml=>@task, :location=>task_url(@task), :status=>:created }
        format.json { render :json=>@task, :location=>task_url(@task), :status=>:created }
      end
    else
      task = Task.reserve!(authenticated)
      render :nothing=>true, :location=>task_url(task), :status=>:see_other
    end
  end


  def update
    # TODO: conditional put
    raise ActiveRecord::StaleObjectError, 'This task already completed.' if @task.completed?
    input = params[:task]
    input[:outcome_type] ||= suggested_outcome_type unless @task.outcome_type
    filter = @task.filter_update_for(authenticated)
    raise NotAuthorized, 'You are not allowed to change this task.' unless filter
    input = filter[input]
    raise NotAuthorized, 'You cannot make this change.' unless input

    @task.update_attributes! input
    respond_to do |format|
      format.html { redirect_to task_url }
      format.xml  { render :xml=>@task }
      format.json { render :json=>@task }
    end
  end

  def complete
    raise ActiveRecord::StaleObjectError, 'This task already completed.' if @task.completed?
    raise NotAuthorized, 'You are not allowed to complete this task.' unless @task.can_complete?(authenticated)
    data = params[:task][:data] if params[:task]
    @task.complete!(data)
    respond_to do |format|
      format.xml  { render :xml=>@task }
      format.json { render :json=>@task }
    end
  end

  def destroy
    raise ActiveRecord::StaleObjectError, 'This task already completed, you cannot cancel it.' if @task.completed?
    raise NotAuthorized, 'You are not allowed to cancel this task.' unless @task.can_cancel?(authenticated)
      @task.cancel!
    head :ok
  end

private

  # Authenticate and make sure the instance is accessible.  Use this instead of the authentication
  # filter to allow access control based on token authentication.  Precludes access to cancelled tasks.:w

  def instance_accessible(task)
    # Use _token authentication (HTTP Basic) to authorize stakeholder associated with task
    # otherwise use regular authentication.
    authenticate_with_http_basic do |login, token|
      @authenticated = instance.authorize(token) if login == '_token'
    # Task accessible if:
    # - Authenticated user is stakeholder
    # - Task has not been cancelled (deleted)
    end or authenticate
    task.stakeholder?(authenticated) && !task.cancelled? if authenticated
  end

  # Return 403 (Forbidden) when accessing a reserved task (show, complete)
  def forbid_reserved
    raise ActiveRecord::RecordNotFound if @task && @task.reserved?
  end

  # Determines the outcome content type based on the request content type.
  def suggested_outcome_type
    Task::OUTCOME_MIME_TYPES.include?(request.content_type) ? request.content_type : Mime::XML
  end

end
