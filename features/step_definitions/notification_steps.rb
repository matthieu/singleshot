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


Given /^the notification$/ do |yaml|
  args = YAML.load(yaml)
  args['recipients'] = Person.identify(Array(args['recipients']))
  Notification.create! args
end

When /^I post this request to \/notifications$/ do |json|
  http_accept :json
  request_page '/notifications', :post, ActiveSupport::JSON.decode(json)
  http_accept :html
end

Then /^I should receive the email$/ do |yaml|
  email = ActionMailer::Base.deliveries.first
  email.should_not be_nil
  YAML.load(yaml).each do |name, value|
    Array(email.send(name.downcase.underscore)).join.strip.should == value
  end
end
