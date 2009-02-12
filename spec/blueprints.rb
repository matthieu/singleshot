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


Person.blueprint do
  email 'john.smith@example.com'
  password 'secret'
end

class Person #:nodoc:
  class << self
    # Returns the person (or array of people) with the specified identity. Makes a new person if necessary.
    # For example:
    #   Person.named('john')
    #   Person.named('alice', 'bob')
    def named(*args)
      return args.map { |arg| Person.named(arg) } if args.size > 1
      Person.identify(args.first) rescue Person.make(:email=>"#{args.first}@example.com")
    end

    # Convenient methods for roles, so owner() returns owner, and so forth.
    [:creator, :owner, :supervisor, :potential, :excluded, :observer, :other].each do |role|
      define_method(role) { Person.named(role.to_s) }
    end
  end
end


Task.blueprint do
  title        { 'Spec me' }
  status       { :available }
  object.stakeholders.build :role=>:supervisor, :person=>Person.supervisor
  object.stakeholders.build :role=>:creator, :person=>Person.creator
  object.stakeholders.build :role=>:potential_owner, :person=>Person.owner     # so owner can claim task
  object.stakeholders.build :role=>:potential_owner, :person=>Person.potential # so owner is not selected by default
  object.stakeholders.build :role=>:observer, :person=>Person.observer
  object.stakeholders.build :role=>:excluded_owner, :person=>Person.excluded
  object.owner ||= Person.owner if object.status == :active || object.status == :completed
end

class Task
  class << self
    [:active, :suspended, :cancelled, :completed].each do |status|
      define_method("make_#{status}") { Task.make :status=>status }
    end
  end
end


Stakeholder.blueprint do
  person { Person.make }
  role   { :owner }
  task   { Task.make }
end


Webhook.blueprint do
  task   { Task.make }
  event  { 'completed' }
  url    { 'http://example.com/completed' }
end
