# Singleshot  Copyright (C) 2008-2009  Intalio, Inc
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


class TasksController < ApplicationController #:nodoc:

  #skip_filter :authenticate, :only=>[:opensearch]

  respond_to :html, :json, :xml
  verify :params=>:task, :only=>[:create, :update], :render=>{:text=>'Missing task', :status=>:bad_request}
  before_filter :task, :only=>[:show, :update]

  def index
    @tasks = authenticated.tasks.pending.with_stakeholders
    respond_with presenting(:task_list, @tasks), :action=>'index', :to=>[:html, :json, :xml, :atom]
  end

  def create
    @task = authenticated.tasks.create!(map_stakeholders(params['task']))
    respond_with presenting(@task), :status=>:created, :location=>@task
  end

  def show
    respond_with presenting(@task), :action=>'show'
  end

  verify :only=>[:update], :unless=>lambda { authenticated.can_update?(task) },
    :render=>{ :text=>'You are not authorized to change this task', :status=>:unauthorized }
  def update
    @task.update_attributes! map_stakeholders(params[:task])
    respond_with presenting(@task), :redirect_to=>@task
  end

protected

  def task
    @task ||= authenticated.tasks.find(params[:id])
  end

  def map_stakeholders(attrs)
    return attrs unless attrs['stakeholders']
    stakeholders = Array(attrs['stakeholders']).map { |sh| Stakeholder.new :role=>sh['role'], :person=>Person.identify(sh['person']) }
    attrs.update('stakeholders'=>stakeholders)
  end

=begin

  def index
    @title, @subtitle = 'Tasks', 'Tasks you are performing or can claim for your own.'
    @alternate = { Mime::HTML=>tasks_url,
                   Mime::ATOM=>tasks_url(:format=>:atom, :access_key=>authenticated.access_key), 
                   Mime::ICS=>tasks_url(:format=>:ics, :access_key=>authenticated.access_key) }
    @tasks = Task.pending.for_stakeholder(authenticated).with_stakeholders.rank_for(authenticated)
    respond_with @tasks
  end

  def completed
    @title, @subtitle = 'Completed', 'Completed tasks'
    @alternate = { Mime::HTML=>completed_tasks_url,
                   Mime::ATOM=>completed_tasks_url(:format=>:atom, :access_key=>authenticated.access_key), 
                   Mime::ICS=>completed_tasks_url(:format=>:ics, :access_key=>authenticated.access_key) }
    @tasks = Task.completed.for_stakeholder(authenticated).with_stakeholders
    respond_with @tasks
    #@graph = Task.connection.select_values("SELECT tasks.updated_at FROM tasks, stakeholders WHERE stakeholders.task_id = tasks.id AND person_id=#{authenticated.id} AND role='owner' AND status='completed' AND tasks.updated_at >= '#{Date.current - 1.month}'")
  end

  def following
    @title, @subtitle = 'Following', 'Tasks you created, observing or managing.'
    @alternate = { Mime::HTML=>following_tasks_url,
                   Mime::ATOM=>following_tasks_url(:format=>:atom, :access_key=>authenticated.access_key), 
                   Mime::ICS=>following_tasks_url(:format=>:ics, :access_key=>authenticated.access_key) }
    @tasks = Task.following.for_stakeholder(authenticated).with_stakeholders
    respond_with @tasks, :action=>'tasks'
  end

  def search
    @query = @title = params['query'] || ''
    #@alternate = { Mime::HTML=>search_url('query'=>@query)
    #               Mime::ATOM=>tasks_url(:format=>:atom, :access_key=>authenticated.access_key), 
    #               Mime::ICS=>tasks_url(:format=>:ics, :access_key=>authenticated.access_key) }
    ids = Task.find_id_by_contents(@query).last.map { |h| h[:id] }
    @tasks = Task.for_stakeholder(authenticated).with_stakeholders.find(:all, :conditions=>{ :id=>ids })
    respond_with @tasks, :action=>'tasks'
  end

  def opensearch
    render :template=>'tasks/opensearch.builder', :content_type=>'application/opensearchdescription', :layout=>false
  end


  def complete_redirect
    render :text=>"<script>frames.top.location.href='#{tasks_url}'</script>"
  end

  def complete
    update = (params[:task] || {}).update(:status=>'completed')
    @task.modify_by(authenticated).update_attributes!(update)
    respond_to do |wants|
      wants.html { redirect_to tasks_url }
      # TODO: wants.xml
      # TODO: wants.json
    end
  end

  def activities
    @activities = @task.activities
    @title = "Activities - #{@task.title}"
    @subtitle = "Track all activities in the task #{@task.title}"
    @alternate = { Mime::HTML=>task_activity_url(@task),
                   Mime::ATOM=>task_activity_url(@task, :format=>:atom, :access_key=>authenticated.access_key),
                   Mime::ICS=>task_activity_url(@task, :format=>:ics, :access_key=>authenticated.access_key) }
    respond_to do |want|
      want.html { @graph = @activities ; render :action=>'index' }
      want.atom { render :action=>'index' }
      want.ics  { render :action=>'index' }
    end
  end

private

  # Determines the outcome content type based on the request content type.
  def suggested_outcome_type
    Task::OUTCOME_MIME_TYPES.include?(request.content_type) ? request.content_type : Mime::XML
  end
=end

end
