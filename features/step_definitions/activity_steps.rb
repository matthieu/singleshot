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


Then /^the activity log shows the entries$/ do |entries|
  activities = Activity.all(:order=>'id').map { |activity|
    person, task = activity.person, activity.task
    I18n.t("activity.#{activity.name}", :person=>activity.person.to_param, :task=>activity.task.title) }
  activities.should == entries.split("\n")
end
