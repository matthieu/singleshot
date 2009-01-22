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

    def defaults(attributes = {})
      #{ :title=>'Test this',
      #  :outcome_url=>'http://test.host/outcome' }.merge(attributes)
      attributes.reverse_merge(:title=>'Add more specs')
    end

    def task_with_status(status, attributes = nil)
      attributes ||= {}
      attributes = attributes.reverse_merge(:admins=>person('admin'))
      task = case status
      when 'active'
        Task.create!(defaults(attributes).merge(:status=>'active', :owner=>person('owner')))
      when 'completed' # Start as active, modified by owner.
        active = task_with_status('active', attributes)
        active.modify_by(person('owner')).update_attributes! :status=>'completed'
        active
      when 'cancelled', 'suspended' # Start as active, modified by admin.
        active = task_with_status('ready', attributes)
        active.modify_by(person('admin')).update_attributes! :status=>status
        active
      else
        Task.create!(defaults(attributes).merge(:status=>status))
      end

      def task.transition_to(status, attributes = nil)
        attributes ||= {}
        modify_by(attributes.delete(:modified_by) || Person.identify('admin')).update_attributes attributes.merge(:status=>status)
        self
      end
      def task.can_transition?(status, attributes = nil)
        transition_to(status, attributes).errors_on(:status).empty?
      rescue ActiveRecord::ReadOnlyRecord
        false
      end
      task
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
