class ActivitiesController < ApplicationController

  access_key_authentication :only=>[:index, :show]
  instance :task, :only=>[:show]

  def index
    @title = 'Activities'
    @alternate = { Mime::ATOM=>formatted_activities_url(:format=>:atom, :access_key=>authenticated.access_key),
                   Mime::ICS=>formatted_activities_url(:format=>:ics, :access_key=>authenticated.access_key) }
    @activities = Activity.for_stakeholder(authenticated)
    day = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i) rescue nil if params[:year]
    dates = day ? day..day + 1.day : Date.today - 3.day..Date.today + 1.day
    @activities = @activities.for_dates(dates)
    respond_to do |want|
      want.html { @days = @activities.group_by_day }
      want.atom
      want.ics
    end
  end

  def show
    @title = "Activities &mdash; #{@task.title}"
    @alternate = { Mime::ATOM=>formatted_activity_url(@task, :atom, :access_key=>authenticated.access_key),
                   Mime::ICS=>formatted_activity_url(@task, :ics, :access_key=>authenticated.access_key) }
    @activities = @task.activities
    respond_to do |want|
      want.html do
        @days = @activities.group_by_day
        render :action=>'index'
      end
      want.atom { render :action=>'index' }
      want.ics  { render :action=>'index' }
    end
  end

end
