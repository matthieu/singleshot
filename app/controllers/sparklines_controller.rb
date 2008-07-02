# Deadline sparkline adapted from Sparklines, 
# Copyright (c) 2005 Geoffrey Grosenbach boss@topfunky.com

class Sparklines

  ## Creates a deadline sparkline.
  #
  # A deadline accepts pre-deadline (negative) and post-deadline (positive
  # values).  The range -1.0 to 0 indicates progress towards the deadline using
  # an increasing clock with the color :progress_color.  The range 0 to 1.0
  # indicates overdue past the deadline using an increasing clock with the
  # color :overdue_color.  Values under -1.0 and over 1.0 are kept within
  # margin.
  #
  #   :diameter - An integer that determines what the size of the sparkline
  #   will be.  Defaults to 20
  #
  #   :progress_color - Color to use for showing progress.  Defaults to
  #   lightblue.
  #
  #   :overdue_color - Color to use for showing overdue.  Defaults to red.
  def deadline
    @options = { :diameter => 20, :background_color => 'transparent',
        :progress_color   => 'lightblue', :overdue_color    => 'red',
        :remain_color     => '#f0f0f0' }.merge(@options)
    Rails.logger.info @data.inspect
    diameter = @options[:diameter].to_f
    create_canvas(diameter, diameter, @options[:background_color])

    if @data[0] <= 0
      progress = 1 + @data[0]
      fill_color = @options[:progress_color]
      remain_color = @options[:remain_color]
    else
      progress = @data[0]
      fill_color = @options[:overdue_color]
      remain_color = @options[:progress_color]
    end

    # Adjust the radius so there's some edge left in the pie
    r = diameter/2.0 - 2
    @draw.fill(remain_color)
    @draw.ellipse(r + 2, r + 2, r , r , 0, 360)
    @draw.fill(fill_color)

    # Special exceptions
    if progress <= 0
      # For 0% return blank
      @draw.draw(@canvas)
      return @canvas
    elsif progress >= 1
      # For 100% just draw a full circle
      @draw.ellipse(r + 2, r + 2, r , r , 0, 360)
      @draw.draw(@canvas)
      return @canvas
    end

    # Okay, this part is as confusing as hell, so pay attention:
    # This line determines the horizontal portion of the point on the circle where the X-Axis
    # should end.  It's caculated by taking the center of the on-image circle and adding that
    # to the radius multiplied by the formula for determinig the point on a unit circle that a
    # angle corresponds to.  360 * progress gives us that angle, but it's in degrees, so we need to
    # convert, hence the muliplication by Pi over 180
    arc_end_x = r + 2 + (r * Math.cos((360 * progress - 90)*(Math::PI/180)))

    # The same goes for here, except it's the vertical point instead of the horizontal one
    arc_end_y = r + 2 + (r * Math.sin((360 * progress - 90)*(Math::PI/180)))

    # Because the SVG path format is seriously screwy, we need to set the large-arc-flag to 1
    # if the angle of an arc is greater than 180 degrees.  I have no idea why this is, but it is.
    progress > 0.5? large_arc_flag = 1: large_arc_flag = 0

    # This is also confusing
    # M tells us to move to an absolute point on the image.  We're moving to the center of the pie
    # h tells us to move to a relative point.  We're moving to the right edge of the circle.
    # A tells us to start an absolute elliptical arc.  The first two values are the radii of the ellipse
    # the third value is the x-axis-rotation (how to rotate the ellipse if we wanted to [could have some fun
    # with randomizing that maybe), the fourth value is our large-arc-flag, the fifth is the sweep-flag,
    # (again, confusing), the sixth and seventh values are the end point of the arc which we calculated previously
    # More info on the SVG path string format at: http://www.w3.org/TR/SVG/paths.html
    path = "M#{r + 2},#{r + 2} v#{-r} A#{r},#{r} 0 #{large_arc_flag},1 #{arc_end_x},#{arc_end_y} z"
    @draw.path(path)

    @draw.draw(@canvas)
    @canvas
  end
end

class SparklinesController < ApplicationController

  skip_before_filter :authenticate

  COLOR_SCHEME = { :above_color=>'#65a0e4', :below_color=>'#a8c0d8', :target=>50, :target_color=>'#ffffd0', :background_color=>'transparent' }

  def index
    expires_in 1.day
    options = COLOR_SCHEME.merge(:type=>'bar', :step=>4).merge(params)
    if options['type'] == 'deadline'
      logger.info 'deadline'
      sparkline = Sparklines.new(params[:results].split(',').map(&:to_f), params)
      render :text=>sparkline.deadline.to_blob, :content_type=>'image/png'
    else
      render :text=>Sparklines.plot(params[:results].split(',').map(&:to_f), options), :content_type=>'image/png'
    end
  end

  def deadline
    #expires_in 1.day
    sparkline = Sparklines.new(params[:results].split(',').map(&:to_f), params)
    render :text=>sparkline.deadline.to_blob, :content_type=>'image/png'
  end

end
