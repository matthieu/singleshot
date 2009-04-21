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


require 'machinist'


Person.blueprint do
  email    { 'john.smith@example.com' }
  password { 'secret' }
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
    ['creator', 'owner', 'supervisor', 'potential', 'excluded', 'past_owner', 'observer', 'other'].each do |role|
      define_method(role) { Person.named(role.to_s) }
    end

    def me
      named(ENV['USER'])
    end
  end
end


Task.blueprint do
  title             { 'Spec me' }
  status            { 'available' }
  creator           { Person.creator }
  supervisors       { [Person.supervisor] }
  potential_owners  { [Person.owner, Person.potential, Person.past_owner] }
  excluded_owners   { [Person.excluded] }
  past_owners       { [Person.past_owner] }
  observers         { [Person.observer] }
  owner             { ['active', 'completed'].include?(status) ? Person.owner : nil }
end

class Task
  class << self
    ['active', 'suspended', 'cancelled', 'completed'].each do |status|
      define_method("make_#{status}") { Task.make :status=>status }
    end

    def spec
      Task.first || Task.make
    end
  end

  # Associate peoples with roles. Returns self. For example:
  #   task.associate :owner=>"john.smith"
  #   task.associate :observer=>observers
  # Note: all previous associations with the given role are replaced.
  def associate(map)
    map.each do |role, identities|
      new_set = [identities].flatten.compact.map { |id| Person.identify(id) }
      keeping = stakeholders.select { |sh| sh.role == role }
      stakeholders.delete keeping.reject { |sh| new_set.include?(sh.person) }
      (new_set - keeping.map(&:person)).each { |person| stakeholders.build :person=>person, :role=>role }
    end
    self
  end

  # Similar to #associate but calls save! and return true if saved.
  def associate!(map)
    associate map
    save!
  end
end


Stakeholder.blueprint do
  person { Person.named('owner') }
  role   { 'owner' }
  task   { Task.make }
end

Activity.blueprint do
  person { Person.named('creator') }
  name   { 'created' }
  task   { Task.make }
end

Webhook.blueprint do
  task   { Task.make }
  event  { 'completed' }
  url    { 'http://example.com/completed' }
end

Form.blueprint do
  task   { Task.make }
end

Template.blueprint do
  title             { 'Spec me' }
  #potential_owners  { [Person.owner, Person.potential_owner] }
end
