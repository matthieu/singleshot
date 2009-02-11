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


module Spec::Helpers #:nodoc:
  # These helper methods and matchers are available only when speccing controllers.
  module Controllers

    # Authenticates as the specified person.
    #
    # You can use this with a block to authenticate only for the duration of a block:
    #   authenticate owner do
    #     ...
    #   end
    #
    # Without arguments, authenticates as 'person'.
    def authenticate(person = Person.named('me'))
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

    # Expecting the URL path to route as specified by the various options. For example:
    #   it { should route('/login', :controller=>'accounts', :action=>'login')
    def route(path, options)
      simple_matcher "route #{path} to #{options.inspect}" do |given, matcher|
        actual = route_for(options)
        matcher.failure_message = "expected '#{path}' but got '#{actual}'"
        actual == path
      end
    end

    # Expecting controller to render a template. You need to perform an action before checking the response. For example:
    #   before { get :index }
    #   it { should render(:template=>'posts/index') }
    def render(options)
      simple_matcher do |given, matcher|
        if template = options.delete(:template)
          matcher.description = "render template #{template.inspect}"
          matcher.failure_message = "expected render of #{template.inspect} but got #{response.rendered[:template].to_s.inspect}"
          Spec::Rails::Matchers::RenderTemplate.new(template.to_s, given).matches?(response)
        else
          false
        end
      end
    end

    # Expecting response to redirect to the given URL. You can use this matcher with
    # response or subject, for example:
    # it 'should redirect to root_url' do
    #   response.should redirect_to(root_url)
    # end
    # it { should redirect_to(root_url) }
    def redirect_to(url_options)
      redirect_to = Spec::Rails::Matchers::RedirectTo.new(request, url_options)
      simple_matcher do |given, matcher|
        returning redirect_to.matches?(response) do
          matcher.description = redirect_to.description
          matcher.failure_message = redirect_to.failure_message
          matcher.negative_failure_message = redirect_to.negative_failure_message
        end
      end
    end

    def respond_with(status, headers = {})
      simple_matcher "respond with #{status}" do |given, matcher|
        response.code == status.to_s
      end
    end
  end
end

Spec::Runner.configure { |config| config.include Spec::Helpers::Controllers, :type=>:controller }
