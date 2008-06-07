class SparklinesController < ApplicationController

  skip_before_filter :authenticate

  def index
    options = { :type=>'bar', :step=>4, :above_color=>'#65a0e4', :below_color=>'#a8c0d8', :target=>50, :target_color=>'#ffffd0' }
    render :text=>Sparklines.plot(params[:results].split(',').map(&:to_f), options.merge(params)), :content_type=>'image/png'
  end

end
