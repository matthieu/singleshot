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
    @instance = instance.to_task
    instance.data = params['data']
    if params['status'] == 'completed'
      instance.update_attributes! :status=>'completed'
      render :text=>"<script>top.window.location.replace('#{CGI.escapeHTML(root_path)}')</script>"
    else
      instance.save!
      render :text=>"<script>top.window.location.replace('#{CGI.escapeHTML(task_url(instance))}')</script>"
    end
  end

  def update
    instance.data = params['data']
    if params['status'] == 'completed'
      instance.update_attributes! :status=>'completed'
      render :text=>"<script>top.window.location.replace('#{CGI.escapeHTML(root_path)}')</script>"
    else
      instance.save!
      redirect_to :back
    end
  end

private

  helper_method :instance
  def instance
    @instance ||= authenticated.task(params['id']) rescue authenticated.template(params['id'])
  end

  def presenter
    @presenter ||= presenting(instance)
  end

end
