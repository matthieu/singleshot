class ActivitiesController < ApplicationController

  access_key_authentication :only=>[:show]

  def show
    @title = 'Activities'
    @alternate = { Mime::ATOM=>formatted_activity_url(:format=>:atom, :access_key=>authenticated.access_key),
                   Mime::ICS=>formatted_activity_url(:format=>:ics, :access_key=>authenticated.access_key) }
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

end
