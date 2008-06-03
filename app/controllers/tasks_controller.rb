class TasksController < ApplicationController

  access_key_authentication :only=>[:index, :completed, :following, :show]

  verify :params=>:task, :only=>:update, :render=>{:text=>'Missing task', :status=>:bad_request}
  before_filter :set_task, :only=>[:show, :update, :complete, :destroy]


  def index
    @title, @subtitle = 'Tasks', 'Tasks you are performing or can claim for your own.'
    @alternate = { Mime::ATOM=>formatted_tasks_url(:format=>:atom, :access_key=>authenticated.access_key), 
                   Mime::ICS=>formatted_tasks_url(:format=>:ics, :access_key=>authenticated.access_key) }
    @tasks = Task.pending.for_stakeholder(authenticated).with_stakeholders.rank_for(authenticated)
    respond_to do |wants|
      wants.html
      # TODO: wants.xml
      # TODO: wants.json
      wants.atom
      wants.ics
    end
  end

  def completed
    @title, @subtitle = 'Completed', 'Completed tasks'
    @alternate = { Mime::ATOM=>formatted_completed_tasks_url(:format=>:atom, :access_key=>authenticated.access_key), 
                   Mime::ICS=>formatted_completed_tasks_url(:format=>:ics, :access_key=>authenticated.access_key) }
    @tasks = Task.completed.for_stakeholder(authenticated).with_stakeholders
    respond_to do |wants|
      wants.html
      # TODO: wants.xml
      # TODO: wants.json
      wants.atom { render :action=>'index' }
      wants.ics  { render :action=>'ics' }
    end
  end

  def following
    @title, @subtitle = 'Following', 'Tasks you created, observing or managing.'
    @alternate = { Mime::ATOM=>formatted_following_tasks_url(:format=>:atom, :access_key=>authenticated.access_key), 
                   Mime::ICS=>formatted_following_tasks_url(:format=>:ics, :access_key=>authenticated.access_key) }
    @tasks = Task.following.for_stakeholder(authenticated).with_stakeholders
    respond_to do |wants|
      wants.html
      # TODO: wants.xml
      # TODO: wants.json
      wants.atom { render :action=>'index' }
      wants.ics  { render :action=>'ics' }
    end
  end

  def show
    @title = @task.title
    @alternate = { Mime::ICS=>formatted_tasks_url(:format=>:ics, :access_key=>authenticated.access_key) }
    respond_to do |wants|
      wants.html { render :layout=>'head' }
      # TODO: wants.xml
      # TODO: wants.json
      wants.ics  do
        @title = @task.title
        @tasks = [@task]
        render :action=>'index'
      end
    end
  end

  def update
    # TODO: rescue ActiveRecord::ReadOnlyRecord
    logger.info @task.inspect
    logger.info @task.readonly?
    logger.info params[:task].inspect
    @task.modified_by(authenticated).update_attributes!(params[:task])

=begin
    # TODO: conditional put
    raise ActiveRecord::StaleObjectError, 'This task already completed.' if @task.completed?
    input = params[:task]
    input[:outcome_type] ||= suggested_outcome_type unless @task.outcome_type
    filter = @task.filter_update_for(authenticated)
    raise NotAuthorized, 'You are not allowed to change this task.' unless filter
    input = filter[input]
    raise NotAuthorized, 'You cannot make this change.' unless input
    @task.update_attributes! input
=end
    respond_to do |wants|
      wants.html { flash['highlight'] = dom_id(@task) ; redirect_to :back }
      # TODO: wants.xml
      # TODO: wants.json
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

  def set_task
    @task = Task.for_stakeholder(authenticated).with_stakeholders.find(params[:id])
  end

  # Determines the outcome content type based on the request content type.
  def suggested_outcome_type
    Task::OUTCOME_MIME_TYPES.include?(request.content_type) ? request.content_type : Mime::XML
  end

end
