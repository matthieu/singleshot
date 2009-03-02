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


# Example:
#   When I post this request to create a task
#     """
#     { task: { title: "expenses" }}
#     """
When /^I post this request to create a task$/ do |request|
  http_accept :json
  request_page '/tasks', :post, ActiveSupport::JSON.decode(request)
end

# Example:
#   When I request json representation of the task "expenses"
When /^I request (.*) representation of the task "(.*)"$/ do |format, title|
  http_accept format
  request_page task_url(Task.find_by_title(title)), :get, nil
end


Then /^the response looks like this$/ do |match|
  body.should == match
end

Then /^the response should be a task$/ do
  json = ActiveSupport::JSON.decode(body)
  json.keys.should == ['task']
end

Then /^the response should be a new task$/ do
  status.should == 201
  response.location.should == task_url(Task.last)
  Then "the response should be a task"
end

Then /^the (.*) of the task should be (.*)$/ do |attribute, value|
  task = ActiveSupport::JSON.decode(body)['task']
  case attribute
  when 'creator', 'owner', 'potential_owner', 'past_owner', 'excluded_owner', 'observer', 'supervisor'
    task['stakeholders'].select { |sh| sh['role'] == attribute }.map { |sh| sh['person'] }.should include(value)
  else
    task[attribute].inspect.should == value
  end
end

# Example:
#   Then the response task title should be "expenses"
Then /^the response task (.*) should be (.*)$/ do |attribute, value|
  task = ActiveSupport::JSON.decode(body)['task']
  case attribute
  when 'creator', 'owner', 'potential_owner', 'past_owner', 'excluded_owner', 'observer', 'supervisor'
    task['stakeholders'].select { |sh| sh['role'] == attribute }.map { |sh| sh['person'] }.should include(value)
  else
    task[attribute].inspect.should == value
  end
end

# Example:
#   Then the response task should have no supervisor
Then /^the response task should have no (.*)$/ do |attribute|
  task = ActiveSupport::JSON.decode(body)['task']
  case attribute
  when 'creator', 'owner', 'potential_owner', 'past_owner', 'excluded_owner', 'observer', 'supervisor'
    task['stakeholders'].select { |sh| sh['role'] == attribute }.should be_empty
  else
    task[attribute].should be_nil
  end
end

# Example:
#   Then people associated with the task are
#     """
#     creator: scott
#     supervisor: alice, bob
#     """
Then /^people associated with the task are$/ do |roles_people|
  expecting = roles_people.split("\n").inject({}) { |hash, line| role, *names = line.split(/[:, ]+/) ; hash.update(role=>Array(names).sort) }
  actual = ActiveSupport::JSON.decode(body)['task']['stakeholders'].
    inject({}) { |hash, sh| role = sh['role'] ; hash.update(role=>Array(hash[role]).push(sh['person']).sort) }
  actual.should == expecting
end
