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
    respond_with presenting(@task), :action=>'show', :layout=>'head'
  end

  verify :only=>[:update], :unless=>lambda { authenticated.can_update?(task) },
    :render=>{ :text=>'You are not authorized to change this task', :status=>:unauthorized }
  def update
    @task.update_attributes! map_stakeholders(params[:task])
    respond_with presenting(@task), :redirect_to=>@task
  end

  def completed
    @tasks = authenticated.tasks.completed.with_stakeholders
    #range = graph.last.first..Date.current %>
    @graph = lambda { authenticated.tasks.completed.group_by { |task| task.updated_at.to_date }.map { |date, entries| entries.size } }
    @datapoints = lambda { [5,9,3,0,4,3,2] }
    respond_with presenting(:task_list, @tasks), :action=>'completed', :to=>[:html, :json, :xml, :atom]
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

end
