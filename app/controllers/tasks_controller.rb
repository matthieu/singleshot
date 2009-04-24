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
    respond_to do |wants|
      wants.html do
        @activities = Activity.visible_to(authenticated).since(Date.today - 1.week).limit(5)
        @templates = authenticated.templates
        render :layout=>'main'
      end
      wants.any { respond_with presenting(:task_list, @tasks), :to=>[:html, :json, :xml, :atom] }
    end
  end

  def new
    @task = authenticated.templates.find(params['from'])
    show
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
    respond_to do |wants|
      wants.html do
        if task.form && !task.form.url.blank?
          @iframe_url = task.form.url
        elsif task.form && !task.form.html.blank?
          @iframe_url = form_url(task)
        end
        render :action=>'show', :layout=>false
      end
      wants.any  { respond_with presenter }
    end
  end

  def update
    return render :text=>'You are not authorized to change this task', :status=>:unauthorized unless authenticated.can_change?(task)
    presenter.update! params['task']
    respond_to do |wants|
      wants.html do
        redirect_to((task.completed? || task.cancelled?) ? tasks_url : :back)
      end
      wants.any  { respond_with presenter }
    end
  end

=begin
  def completed
    @tasks = authenticated.tasks.completed.with_stakeholders
    @datapoints = lambda { authenticated.tasks.completed.group_by { |task| task.updated_at.to_date }.map { |date, entries| entries.size } }
    respond_with presenting(:task_list, @tasks), :action=>'completed', :to=>[:html, :json, :xml, :atom]
  end
=end

protected

  helper_method :task
  def task
    @task ||= authenticated.tasks.find(params['id'])
  end

  def sidebar
    ApplicationHelper::Sidebar.new @activities, @templates
  end

  def presenter
    @presenter ||= presenting(task)
  end

end
