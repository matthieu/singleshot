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


module Spec::Helpers #:nodoc:
  module Common

    def self.included(base) #:nodoc:
      base.after :each do
        Activity.delete_all
        Stakeholder.delete_all
        Task.delete_all
        Person.delete_all
      end
    end

    # Returns a person with the specified identity, creates a new person if necessary. For example:
    #   Task.create! :owner=>person('john'), :creator=>person('mary')
    def person(identity = 'person')
      Person.identify(identity) rescue Person.create!(:email=>"#{identity}@example.com", :password=>'secret')
    end

    # Returns all people with the specified identity, creates them if necessary. A plural version of #person.
    # For example:
    #   people('alice', 'bob', 'mary')
    def people(*identities)
      identities.map { |identity| person(identity) }
    end

    # Convenient methods for roles, so owner() returns owner, and so forth.
    [:creator, :owner, :supervisor, :potential, :excluded, :other].each do |role|
      define_method(role) { person(role.to_s) }
    end

    # Creates and returns a new task. You can pass the task title as the first argument (giving each task
    # a title is highly recommended). You can pass additional task attributes as the last argument, or all
    # task attributes as a single argument. Missing arguments are supplied by calling #defaults. For example:
    #   new_task 'Testing task with defaults'
    #   new_task 'Testing task with data', :data=>{ 'foo'=>'bar' }
    #   new_task :title=>'Testing priority', :priority=>3
    def new_task(*args)
      attrs = args.extract_options!
      attrs[:title] = args.shift if String === args.first
      raise ArgumentError, "Expecting one/two arguments, received #{args.size + 2}" unless args.empty?
      case status = attrs.delete(:status)
      when 'available', nil
        Task.create! defaults(attrs) do |task|
          task.stakeholders.build :role=>:supervisor, :person=>supervisor
          task.stakeholders.build :role=>:creator, :person=>creator
          task.stakeholders.build :role=>:potential_owner, :person=>owner     # so owner can claim task
          task.stakeholders.build :role=>:potential_owner, :person=>potential # so owner is not selected by default
          task.stakeholders.build :role=>:excluded_owner, :person=>excluded
        end
      when 'active'
        returning new_task(attrs) do |task|
          task.update_attributes :owner=>owner
        end
      when 'suspended'
        returning new_task(attrs) do |task|
          task.update_attributes! :status=>'suspended'
        end
      when 'completed'
        returning new_task(attrs.merge(:status=>'active')) do |task|
          task.update_attributes! :status=>'completed'
        end
      when 'cancelled'
        returning new_task() do |task|
          task.update_attributes! :status=>'cancelled'
        end
      else raise "Invalid status code #{status}"
      end
    end

    # Creates and returns new tasks, one for each argument. Each argument can be a string (task title, with
    # all other attributes supplied by #defaults), or a hash of the desired task attributes. For example:
    #   new_tasks 'Task 1', 'Task 2', 'Task 3'
    #   new_tasks({:title=>'P1', :priority=>1}, {:title=>'P5', :priority=>5}) 
    def new_tasks(*args)
      args.map { |arg| new_task(arg) }
    end

    # Merges task attributes with a default set. Useful for creating a task without bothering to specify
    # all (or any) attributes. For example:
    #   subject { Task.new(defaults) }
    #   Task.create! defaults(:title=>'Testing task defaults')
    def defaults(attributes = {})
      attributes.reverse_merge(:title=>'Add more specs')
    end

  end
end

Spec::Runner.configure { |config| config.include Spec::Helpers::Common }


module ActionController
  # TestResponse for functional, CgiResponse for integration.
  class AbstractResponse
    StatusCodes::SYMBOL_TO_STATUS_CODE.each do |symbol, code|
      unless instance_methods.include?("#{symbol}?")
        define_method("#{symbol}?") { self.code == code.to_s }
      end
    end
  end
end
