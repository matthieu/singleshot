class SparklinesController < ApplicationController

  skip_before_filter :authenticate

  COLOR_SCHEME = { :above_color=>'#65a0e4', :below_color=>'#a8c0d8', :target=>50, :target_color=>'#ffffd0', :background_color=>'transparent' }

  def index
    options = COLOR_SCHEME.merge(:type=>'bar', :step=>4).merge(params)
    render :text=>Sparklines.plot(params[:results].split(',').map(&:to_f), options), :content_type=>'image/png'
  end

end
