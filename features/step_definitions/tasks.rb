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


Given /^the person (\S*) exists$/ do |name|
  Person.identify(name) rescue Person.create!(:email=>"#{name}@example.com", :password=>'secret')
end

Given /^a newly created task "([^"]*)"$/ do |title|
  Given "the person creator exists"
  Person.identify('creator').tasks.create!(:title=>title)
end

Given /^a newly created task "(.*?)" assigned to "(\S*)"$/ do |title, person|
  Given "the person creator exists"
  Given "the person #{person} exists"
  Person.identify('creator').tasks.create!(:title=>title, :owner=>Person.identify(person))
end

Given /^owner "(.*)" for "(.*)"$/ do |person, title|
  Given "the person #{person} exists"
  Task.find_by_title(title).stakeholders.create! :role=>:owner, :person=>Person.identify(person)
end

Given /^potential owner "(.*)" for "(.*)"$/ do |person, title|
  Given "the person #{person} exists"
  Task.find_by_title(title).stakeholders.create! :role=>:potential_owner, :person=>Person.identify(person)
end

Given /^supervisor "(.*)" for "(.*)"$/ do |person, title|
  Given "the person #{person} exists"
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


Then /^activity log should show "(\S*) (\S*) (.*)"$/ do |person, name, title|
  http_accept :json
  visit "/activity"
  fail "You forgot to authenticate!" if response.code == "401"
  activities = ActiveSupport::JSON.decode(response_body)['activities']
  fail "No activities returned" unless activities
  matching = activities.select { |activity| activity['name'] == name && activity['person'] == person && activity['task']['title'] == title }
  matching.should_not be_empty
end

Then /^last activity in log should show "(\S*) (\S*) (.*)"$/ do |person, name, title|
  http_accept :json
  visit "/activity"
  fail "You forgot to authenticate!" if response.code == "401"
  activity = ActiveSupport::JSON.decode(response_body)['activities'].last
  fail "No activities returned" unless activity
  [activity['person'], activity['name'], activity['task']['title']].should == [person, name, title]
end
