class OwnersController < ApplicationController

  before_filter :set_task

  def show
    owner = @task.owner
    respond_to do |wants|
      wants.any  { render :text=>owner && owner.identity }
    end
  end

  def update
    # TODO: add access control check
    @task.update_attributes :owner=>params['owner']
    respond_to do |wants|
      wants.html { redirect_to :back }
    end
  end

  def destroy
    # TODO: add access control check
    @task.update_attributes :owner=>nil
    respond_to do |wants|
      wants.html { redirect_to :back }
    end
  end

private

  def set_task
    @task = Task.find(params['task_id'])
    @task.modified_by = authenticated
  end

end
