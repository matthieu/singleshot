class SandwichesController < ApplicationController

  skip_filter :authenticate
  skip_before_filter :verify_authenticity_token
  layout false

  before_filter :instance

  def show
    @read_only = true unless params['perform'] == 'true'
  end

  def update
    @sandwich.update_attributes params['sandwich']
    if @sandwich.save
      flash[:success] = 'Changes have been saved.'
      redirect_to :action=>'show', :task_url=>@task_url, :perform=>true
    else
      render :action=>'show'
    end
  end

  def create
    @sandwich.update_attributes params['sandwich']
    if @sandwich.save
      flash[:success] = 'Changes have been saved.'
      # TODO: FIX!
      render :text=>"<script>frames.top.location.href='http://localhost:3000/tasks'</script>"
    else
      render :action=>'show'
    end
  end

private

  def instance
    #@task_url = params['task_url'] or raise ActiveRecord::RecordNotFound
    #uri = URI(@task_url)
    #xml = REXML::Document.new(open(uri.to_s, :http_basic_authentication=>[uri.user, uri.password]))
    session[:sandwich] = @sandwich = Sandwich.new(session[:sandwich])
    #@read_only = true if @sandwich.status == 'completed'
  end

end
