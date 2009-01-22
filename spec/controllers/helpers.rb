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


require File.dirname(__FILE__) + '/../spec_helper'


# These helper methods and matchers are available only when speccing controllers.
module Spec::Helpers #:nodoc:
  module Controllers

    # Authenticates as the specified person.
    #
    # You can use this with a block to authenticate only for the duration of a block:
    #   authenticate owner do
    #     ...
    #   end
    #
    # Without arguments, authenticates as 'person'.
    def authenticate(person = person('person'))
      previous, session[:person_id] = session[:person_id], person.id
      if block_given?
        begin
          yield
        ensure
          session[:person_id] = previous
        end
      end
    end

    # Returns the currently authenticated person.
    def authenticated
      Person.find(session[:person_id]) if session[:person_id] 
    end

    # Returns true if the previous request was authenticated and authorized.
    def authorized?
      !(response.redirected_to == session_url || response.code == '401')
    end

  end
end

Spec::Runner.configure { |config| config.include Spec::Helpers::Controllers, :type=>:controller }
