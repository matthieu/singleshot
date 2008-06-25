class ActivityController < ApplicationController

  access_key_authentication

  def index
    @title = 'Activities'
    @subtitle = 'Track activity in tasks you participate in or observe.'
    @alternate = { Mime::HTML=>activity_url,
                   Mime::ATOM=>formatted_activity_url(:format=>:atom, :access_key=>authenticated.access_key),
                   Mime::ICS=>formatted_activity_url(:format=>:ics, :access_key=>authenticated.access_key) }
    respond_to do |want|
      want.html do
        @graph = Activity.for_stakeholder(authenticated).for_dates(Date.current - 1.month)
        yesterday = Date.yesterday
        @activities = @graph[0,50]
      end
      want.atom { @activities = Activity.for_stakeholder(authenticated).scoped(:limit=>50) }
      want.ics  { @activities = Activity.for_stakeholder(authenticated).scoped(:limit=>50) }
    end
  end

  def for_task
    @task = Task.for_stakeholder(authenticated).find(params[:task_id], :include=>:activities)
    @activities = @task.activities
    @title = "Activities - #{@task.title}"
    @subtitle = "Track all activities in the task #{@task.title}"
    @alternate = { Mime::HTML=>task_activity_url(@task),
                   Mime::ATOM=>formatted_task_activity_url(@task, :format=>:atom, :access_key=>authenticated.access_key),
                   Mime::ICS=>formatted_task_activity_url(@task, :format=>:ics, :access_key=>authenticated.access_key) }
    respond_to do |want|
      want.html { @graph = @activities ; render :action=>'index' }
      want.atom { render :action=>'index' }
      want.ics  { render :action=>'index' }
    end
  end

end
