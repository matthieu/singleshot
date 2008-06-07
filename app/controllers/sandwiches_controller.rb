class SandwichesController < ApplicationController

  skip_filter :authenticate
  skip_before_filter :verify_authenticity_token
  layout false

  before_filter :instance

  def show
  end

  def update
    @sandwich.update_attributes params['sandwich']
    if @sandwich.save(@task['update_url'])
      flash[:success] = 'Changes have been saved.'
      redirect_to :back
    else
      render :action=>'show'
    end
  end

  def create
    @sandwich.update_attributes params['sandwich']
    if @sandwich.save(@task['update_url'], true)
      flash[:success] = 'Changes have been saved.'
      redirect_to @task['redirect_url']
    else
      render :action=>'show'
    end
  end

private

  def instance
    uri = URI(params['task_url'])
    xml = uri.read(:http_basic_authentication=>[uri.user, uri.password], 'Content-Type'=>Mime::XML.to_s)
    @task = Hash.from_xml(xml)['task']
    logger.info @task['update_url']
    @sandwich = Sandwich.new(@task['data'])
  rescue =>error
    logger.error error
    raise ActiveRecord::RecordNotFound
  end

end
