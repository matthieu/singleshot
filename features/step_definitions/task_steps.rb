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


Given /^this task$/ do |task|
  Task.create! YAML.load(task)
end

Given /^the task "(.*)" created by (\S*)$/ do |title, person|
  Given "the person #{person}"
  Person.identify(person).tasks.create!(:title=>title)
end

Given /^the task "(.*)" created by (.*) and assigned to (.*)$/ do |title, person, owner|
  Given "the person #{person}"
  Given "the person #{owner}"
  Person.identify(person).tasks.create!(:title=>title, :owner=>owner)
end

Given /^(.*) is (.*) of task "(.*)"$/ do |person, role, title|
  Given "the person #{person}"
  Task.find_by_title(title).stakeholders.create! :role=>role.sub(' ', '_'), :person=>Person.identify(person)
end

When /I view the task "(.*)"$/ do |title|
  Given "I am authenticated"
  http_accept :html
  request_page task_url(Task.find_by_title(title)), :get, nil
end


When /^(\S*) (claims|releases|suspends|resumes|completes|cancels) the task "(.*)"$/ do |person, action, title|
  task = Person.identify(person).tasks.find(:first, :conditions=>{:title=>title})
  case action
  when 'claims'
    task.update_attributes! :owner=>Person.identify(person)
  when 'releases'
    task.update_attributes! :owner=>nil
  when 'suspends'
    task.update_attributes! :status=>'suspended'
  when 'resumes'
    task.update_attributes! :status=>'active'
  when 'completes'
    task.update_attributes! :status=>'completed'
  when 'cancels'
    task.update_attributes! :status=>'cancelled'
  else fail "Unknown action #{action}"
  end
end

When /^(.*) modifies the (.*) of task "(.*)" to (.*)$/ do |person, attribute, title, value|
  Person.identify(person).tasks.find(:first, :conditions=>{:title=>title}).update_attributes! attribute=>value
end

When /^(.*) delegates the task "(.*)" to (.*)$/ do |person, title, new_owner|
  Given "the person #{new_owner}"
  Person.identify(person).tasks.find(:first, :conditions=>{:title=>title}).update_attributes! :owner=>Person.identify(new_owner)
end


Then /^the task "([^\"]*)" should be (\S+)$/ do |title, status|
  Task.find_by_title(title).status.should == status
end

Then /^the task "([^\"]*)" data should have (.*)="([^\"]*)"$/ do |title, name, value|
  Task.find_by_title(title).data[name].should == value
end

Then /^the task "([^\"]*)" should be owned by (.*)$/ do |title, name|
  owner = name[/no one/] ? nil : Person.identify(name)
  Task.find_by_title(title).owner.should == owner
end
