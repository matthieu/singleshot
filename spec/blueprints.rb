# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with this
# work for additional information regarding copyright ownership.  The ASF
# licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.


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
  status       { 'available' }
  object.stakeholders.build :role=>:supervisor, :person=>Person.supervisor
  object.stakeholders.build :role=>:creator, :person=>Person.creator
  object.stakeholders.build :role=>:potential_owner, :person=>Person.owner     # so owner can claim task
  object.stakeholders.build :role=>:potential_owner, :person=>Person.potential # so owner is not selected by default
  object.stakeholders.build :role=>:observer, :person=>Person.observer
  object.stakeholders.build :role=>:excluded_owner, :person=>Person.excluded
  object.owner ||= Person.owner if object.status == 'active' || object.status == 'completed'
end

class Task
  class << self
    [:active, :suspended, :cancelled, :completed].each do |status|
      define_method("make_#{status}") { Task.make :status=>status.to_s }
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
