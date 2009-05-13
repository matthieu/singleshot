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


class NotificationMailer < ActionMailer::Base
  def notification(notification, recipient)
    subject      notification.subject
    from         "Notifications <notifications@#{default_url_options[:host]}>"
    reply_to     "Do not reply <noreply@#{default_url_options[:host]}>"
    recipients   "#{recipient.fullname} <#{recipient.email}>"
    body         :body => notification.body
    content_type 'text/html'
  end
end
