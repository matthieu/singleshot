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


Given /^a newly created task "([^"]*)"$/ do |title|
  Given %{the person "creator"}
  Person.identify('creator').tasks.create!(:title=>title)
end

Given /^a newly created task "(.*?)" assigned to "(\S*)"$/ do |title, person|
  Given %{the person "creator"}
  Given %{the person "#{person}"}
  Person.identify('creator').tasks.create!(:title=>title, :owner=>Person.identify(person))
end

Given /^owner "(.*)" for "(.*)"$/ do |person, title|
  Given %{the person "#{person}"}
  Task.find_by_title(title).stakeholders.create! :role=>:owner, :person=>Person.identify(person)
end

Given /^potential owner "(.*)" for "(.*)"$/ do |person, title|
  Given %{the person "#{person}"}
  Task.find_by_title(title).stakeholders.create! :role=>:potential_owner, :person=>Person.identify(person)
end

Given /^supervisor "(.*)" for "(.*)"$/ do |person, title|
  Given %{the person "#{person}"}
  Task.find_by_title(title).stakeholders.create! :role=>:supervisor, :person=>Person.identify(person)
end



When /^"(.*)" claims task "(.*)"$/ do |person, title|
  task = Person.identify(person).tasks.find(:first, :conditions=>{:title=>title})
  task.update_attributes! :owner=>Person.identify(person)
end

When /^"(.*)" delegates task "(.*)" to "(.*)"$/ do |person, title, designated|
  Person.identify(person)
  task = Person.identify(person).tasks.find(:first, :conditions=>{:title=>title})
  task.update_attributes! :owner=>Person.identify(designated)
end

When /^"(.*)" releases task "(.*)"$/ do |person, title|
  task = Person.identify(person).tasks.find(:first, :conditions=>{:title=>title})
  task.update_attributes! :owner=>nil
end

When /^"(.*)" suspends task "(.*)"$/ do |person, title|
  task = Person.identify(person).tasks.find(:first, :conditions=>{:title=>title})
  task.update_attributes! :status=>:suspended
end

When /^"(.*)" resumes task "(.*)"$/ do |person, title|
  task = Person.identify(person).tasks.find(:first, :conditions=>{:title=>title})
  task.update_attributes! :status=>:active
end

When /^"(.*)" cancels task "(.*)"$/ do |person, title|
  task = Person.identify(person).tasks.find(:first, :conditions=>{:title=>title})
  task.update_attributes! :status=>:cancelled
end

When /^"(.*)" completes task "(.*)"$/ do |person, title|
  task = Person.identify(person).tasks.find(:first, :conditions=>{:title=>title})
  task.update_attributes! :status=>:completed
end

When /^"(.*)" modifies (\S*) of task "(.*)" to (.*)$/ do |person, attribute, title, value|
  task = Person.identify(person).tasks.find(:first, :conditions=>{:title=>title})
  task.update_attributes! attribute=>value
end



When /^I create a new task with this request$/ do |request|
  http_accept :json
  request_page '/tasks', :post, ActiveSupport::JSON.decode(request)
  status.should == 201
  response.content_type.should == Mime::JSON
  response.location.should == task_url(Task.last)
end

Then /^the response should be a task$/ do
  json = ActiveSupport::JSON.decode(body)
  json.keys.should == ['task']
end

Then /^the (.*) of the response task should be "(.*)"$/ do |attribute, value|
  task = ActiveSupport::JSON.decode(body)['task']
  case attribute
  when 'creator', 'owner', 'potential_owner', 'past_owner', 'excluded_owner', 'observer', 'supervisor'
    task['stakeholders'].select { |sh| sh['role'] == attribute }.map { |sh| sh['person'] }.should include(value)
  else
    task[attribute].should == value
  end
end

Then /^the response task should have no (.*)$/ do |attribute|
  task = ActiveSupport::JSON.decode(body)['task']
  case attribute
  when 'creator', 'owner', 'potential_owner', 'past_owner', 'excluded_owner', 'observer', 'supervisor'
    task['stakeholders'].select { |sh| sh['role'] == attribute }.should be_empty
  else
    task[attribute].should be_nil
  end
end
