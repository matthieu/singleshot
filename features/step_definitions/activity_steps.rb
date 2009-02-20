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


Then /^activity log should include "(\S*) (\S*) (.*)"$/ do |person, name, title|
  http_accept :json
  visit path_to('activity page')
  fail "You forgot to authenticate!" if response.code == "401"
  activities = ActiveSupport::JSON.decode(response_body)['activities']
  fail "No activities returned" unless activities
  matching = activities.select { |activity| activity['name'] == name && activity['person'] == person && activity['task']['title'] == title }
  matching.should_not be_empty
end

Then /^last activity in log should be "(\S*) (\S*) (.*)"$/ do |person, name, title|
  http_accept :json
  visit "/activity"
  fail "You forgot to authenticate!" if response.code == "401"
  activity = ActiveSupport::JSON.decode(response_body)['activities'].last
  fail "No activities returned" unless activity
  [activity['person'], activity['name'], activity['task']['title']].should == [person, name, title]
end
