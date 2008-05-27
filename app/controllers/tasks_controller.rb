class TasksController < ApplicationController

  access_key_authentication :only=>[:index, :completed, :following, :show]

  verify :params=>:task, :only=>:update, :render=>{:text=>'Missing task', :status=>:bad_request}
  before_filter :authenticate, :except=>[:show, :update, :complete, :destroy]
  instance :task, :only=>[:show, :update, :complete, :destroy], :check=>:instance_accessible
  before_filter :forbid_reserved, :except=>[:update, :destroy]

  def index
    @title, @subtitle = 'Tasks', 'Tasks you are performing or can claim for your own.'
    @alternate = { Mime::ATOM=>formatted_tasks_url(:format=>:atom, :access_key=>authenticated.access_key), 
                   Mime::ICS=>formatted_tasks_url(:format=>:ics, :access_key=>authenticated.access_key) }
    @tasks = Task.pending.for_stakeholder(authenticated).with_stakeholders.rank_for(authenticated)
    respond_to do |format|
      format.html
      # TODO: format.xml
      # TODO: format.json
      format.atom
      format.ics
    end
  end

  def completed
    @title, @subtitle = 'Completed', 'Completed tasks'
    @alternate = { Mime::ATOM=>formatted_completed_tasks_url(:format=>:atom, :access_key=>authenticated.access_key), 
                   Mime::ICS=>formatted_completed_tasks_url(:format=>:ics, :access_key=>authenticated.access_key) }
    @tasks = Task.completed.for_stakeholder(authenticated).with_stakeholders
    respond_to do |format|
      format.html do 
        @days = @tasks.group_by { |task| task.updated_at.to_date }
        render :template=>'tasks/by_day'
      end
      # TODO: format.xml
      # TODO: format.json
      format.atom { render :action=>'index' }
      format.ics  { render :action=>'ics' }
    end
  end

  def following
    @title, @subtitle = 'Following', 'Tasks you created, observing or managing.'
    @alternate = { Mime::ATOM=>formatted_following_tasks_url(:format=>:atom, :access_key=>authenticated.access_key), 
                   Mime::ICS=>formatted_following_tasks_url(:format=>:ics, :access_key=>authenticated.access_key) }
    @tasks = Task.following.for_stakeholder(authenticated).with_stakeholders
    respond_to do |format|
      format.html do 
        @days = @tasks.group_by { |task| task.updated_at.to_date }
        render :template=>'tasks/by_day'
      end
      # TODO: format.xml
      # TODO: format.json
      format.atom { render :action=>'index' }
      format.ics  { render :action=>'ics' }
    end
  end


  def show
    @alternate = { Mime::ICS=>formatted_tasks_url(:format=>:ics, :access_key=>authenticated.access_key) }
    respond_to do |format|
      format.html { render :layout=>'head' }
      format.xml  { render :xml=>@task }
      format.json { render :json=>@task }
      format.ics  do
        @title = @task.title
        @tasks = [@task]
        render :action=>'index'
      end
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
