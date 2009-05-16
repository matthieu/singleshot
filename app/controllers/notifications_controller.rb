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

  verify :params=>'notification', :only=>:create, :render=>{ :status=>:bad_request }
  def create
    creator = params['notification'].delete('creator') || authenticated
    recipients = Array(params['notification'].delete('recipients'))
    @notification = Notification.create!(params['notification'].merge(:creator=>Person.identify(creator),
                                                                      :recipients=>Person.identify(recipients)))
    respond_to do |wants|
      wants.html { redirect_to notifications_url, :status=>:see_other }
      wants.any  { respond_with presenting(@notification), :status=>:created, :location=>@notification }
    end
  end

  def show
    respond_to do |wants|
      wants.html { copy.read! }
      wants.any  { respond_with presenting(notification) }
    end
  end

  def update
    copy.read! if params['read']
    head :ok
  end

protected

  helper_method :notification, :copy
  def notification
    @notification ||= copy.notification
  end

  def copy
    @copy ||= authenticated.notification(params['id']) or fail ActiveRecord::RecordNotFound
  end

end
