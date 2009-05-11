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


class NotificationsController < ApplicationController #:nodoc:
  respond_to :html, :json, :xml

  def index
    @copies = authenticated.notifications.paginate(:page=>params['page'], :per_page=>50)
    respond_to do |wants|
      wants.html
      wants.any { respond_with presenting(@copies.map(&:notification), :name=>'notifications') }
    end
  end

  def create
    @notification = Notification.new :creator=>authenticated
    @presenter = presenting(@notification)
    @presenter.update! params['notification']
    respond_to do |wants|
      wants.html { redirect_to notifications_url, :status=>:see_other }
      wants.any  { respond_with @presenter, :status=>:created, :location=>@notification }
    end
  end

  def show
    respond_to do |wants|
      wants.html { instance.read! }
      wants.any  { respond_with presenting(instance.notification) }
    end
  end

protected

  helper_method :instance
  def instance
    @instance ||= authenticated.notification(params['id']) or fail ActiveRecord::RecordNotFound
  end
end
