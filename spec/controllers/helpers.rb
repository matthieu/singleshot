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
      previous, session[:authenticated] = session[:authenticated], person.id
      if block_given?
        begin
          yield
        ensure
          session[:authenticated] = previous
        end
      end
      self
    end

    def session_for(person)
      { :authenticated=>person.id }
    end

    # Returns the currently authenticated person.
    def authenticated
      Person.find(session[:authenticated]) if session[:authenticated] 
    end

    # Returns true if the previous request was authenticated and authorized.
    def authorized?
      !(response.redirected_to == session_url || response.code == '401')
    end

    # Expecting the URL path to route as specified by the various options. For example:
    #   it { should route('/login', :controller=>'accounts', :action=>'login')
    #   it { should route(:post, '/post', :controller=>'posts', :action=>'create')
    def route(*args)
      method = Symbol === args.first ? args.shift : :get
      path = args.shift
      options = args.last || {}
      simple_matcher "route #{method} #{path} to #{options.inspect}" do |given, matcher|
        matcher.failure_message = "expected '#{options.inspect}' but got '#{params_from(method, path).inspect}'"
        params_from(method, path) == options
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

    def respond_with(*args) #status, headers = {})
      expect = args.extract_options!.stringify_keys
      actual = response.headers.slice(*expect.keys)
      case args.first
      when Numeric
        expect['Status'] = args.shift.to_s
      when String
        expect['Template'] = args.shift.to_s
      end
      actual['Status'] = response.code if expect.has_key?('Status')
      actual['Template'] = response.rendered[:template].to_s if expect.has_key?('Template')
      simple_matcher "respond with #{expect.inspect}" do |given, matcher|
        matcher.failure_message = "expected #{expect.inspect} but got #{actual.inspect}"
        expect == actual
      end
    end
  end
end

Spec::Runner.configure { |config| config.include Spec::Helpers::Controllers, :type=>:controller }
