class SandwichesController < ApplicationController

  before_filter :instance
  before_filter :update_instance, :only=>[:update, :create]
  skip_filter :authenticate
  layout false

  def show
    @read_only = true unless params['perform'] == 'true'
  end

  def update
    if @sandwich.save
      flash[:success] = 'Changes have been saved.'
      redirect_to :action=>'show', :task_url=>@task_url, :perform=>true
    else
      render :action=>'show'
    end
  end

  def create
    if @sandwich.complete
      flash[:success] = 'Thank you.  Sandwich created!'
      redirect_to :action=>'show', :task_url=>@task_url, :perform=>true
    else
      render :action=>'show'
    end
  end

private

  def instance
    @task_url = params['task_url'] or raise ActiveRecord::RecordNotFound
    @sandwich = Sandwich.load(@task_url)
    @read_only = true if @sandwich.status == 'completed'
  end

  def update_instance
    if params = self.params['sandwich']
      params['toppings'] = params['toppings'] * ';'
      @sandwich.attributes = params
    else
      head :bad_request
    end 
  end

end
