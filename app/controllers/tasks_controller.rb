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

  respond_to :html, :json, :xml
  verify :params=>:task, :only=>[:create, :update], :render=>{:text=>'Missing task', :status=>:bad_request}
  before_filter :task, :only=>[:show, :update]

  def index
    @tasks = authenticated.tasks.pending.with_stakeholders
    respond_with presenting(:task_list, @tasks), :action=>'index', :to=>[:html, :json, :xml, :atom], :layout=>'main'
  end

  def create
    @task = authenticated.tasks.new
    presenter.update! params['task']
    respond_to do |wants|
      wants.html { redirect_to tasks_url, :status=>:see_other }
      wants.any  { respond_with presenter, :status=>:created, :location=>@task }
    end
  end

  def show
    if task.form && !task.form.url.blank?
	    @iframe_url = task.form.url
	  elsif task.form && !task.form.html.blank?
		  @iframe_url = form_url(task)
		end
    respond_with presenter, :action=>'show', :layout=>false
  end

  verify :only=>[:update], :unless=>lambda { authenticated.can_update?(task) },
    :render=>{ :text=>'You are not authorized to change this task', :status=>:unauthorized }
  def update
    presenter.update! params['task']
    respond_to do |wants|
      wants.html do
        redirect_to((task.completed? || task.cancelled?) ? tasks_url : :back)
      end
      wants.any  { respond_with presenter }
    end
  end

  def completed
    @tasks = authenticated.tasks.completed.with_stakeholders
    @datapoints = lambda { authenticated.tasks.completed.group_by { |task| task.updated_at.to_date }.map { |date, entries| entries.size } }
    respond_with presenting(:task_list, @tasks), :action=>'completed', :to=>[:html, :json, :xml, :atom]
  end

protected

  helper_method :task
  def task
    @task ||= authenticated.tasks.find(params['id'])
  end

  def sidebar
    { :activity=>Activity.visible_to(authenticated).all(:limit=>5),
      :templates=>[] }
  end

  def presenter
    @presenter ||= presenting(task)
  end

end
