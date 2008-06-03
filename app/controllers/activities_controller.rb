class ActivitiesController < ApplicationController

  access_key_authentication :only=>[:index, :show]

  def index
    @title = 'Activities'
    @subtitle = 'Track activity in tasks you participate in or observe.'
    @alternate = { Mime::ATOM=>formatted_activities_url(:format=>:atom, :access_key=>authenticated.access_key),
                   Mime::ICS=>formatted_activities_url(:format=>:ics, :access_key=>authenticated.access_key) }
    @activities = Activity.for_stakeholder(authenticated)
    day = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i) rescue nil if params[:year]
    dates = day ? day..day + 1.day : Date.today - 3.day..Date.today + 1.day
    @activities = @activities.for_dates(dates)
    respond_to do |want|
      want.html
      want.atom
      want.ics
    end
  end

  def show
    @task = Task.for_stakeholder(authenticated).find(params[:id], :include=>:activities)
    @activities = @task.activities
    @title = "Activities - #{@task.title}"
    @subtitle = "Track all activities in the task #{@task.title}"
    @alternate = { Mime::ATOM=>formatted_activity_url(@task, :atom, :access_key=>authenticated.access_key),
                   Mime::ICS=>formatted_activity_url(@task, :ics, :access_key=>authenticated.access_key) }
    respond_to do |want|
      want.html { render :action=>'index' }
      want.atom { render :action=>'index' }
      want.ics  { render :action=>'index' }
    end
  end

end
