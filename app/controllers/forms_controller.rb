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


class FormsController < ApplicationController #:nodoc:

  layout false

  def show
  end

  def create
    args = task.to_hash.merge(:data=>params['data'], :owner=>authenticated)
    @task = authenticated.tasks.create!(args)
    @task.update_attributes! :status=>'completed' if params['status'] == 'compeleted'
    render :text=>"<script>top.window.location.replace('#{CGI.escapeHTML(task_url(@task))}')</script>"
  end

  def update
    task.update_attributes! :status=>params['status'] || task.status, :data=>params['data']
    if task.completed? || task.cancelled?
      render :text=>"<script>top.window.location.replace('#{CGI.escapeHTML(root_path)}')</script>"
    else
      redirect_to :back
    end
  end

private

  helper_method :task
  def task
    @task ||= authenticated.tasks.find(params['id']) rescue authenticated.templates.find(params['id'])
  end

end
