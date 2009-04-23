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
      previous, session[:authenticated] = session[:authenticated], person && person.id
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

    def json(entity = nil)
      unless entity
        run_action!
        entity = response.body
      end
      ActiveSupport::JSON.decode(entity)
    end

    def xml(entity = nil)
      unless entity
        run_action!
        entity = response.body
      end
      Hash.from_xml(entity)
    end

    def back
      "http://test.host/back"
    end

    # Expecting response with 201 Created and the specified location URL. For example:
    #   should_respond_with_created 'http://localhost/new_resource'
    #   should_respond_with_created { task_url(Task.last) }
    def respond_with_created(url = nil, &block)
      simple_matcher "respond with created #{url}" do |given|
        run_action!
        response.code == '201' && response['Location'] == (url || instance_eval(&block))
      end
    end

  end
end

Spec::Runner.configure do |config|
  config.include Spec::Helpers::Controllers, :type=>:controller
  config.before :each, :type=>:controller do
    rescue_action_in_public!
    request.env["HTTP_REFERER"] = '/back'
  end
  config.after :each do
    I18n.locale = nil 
    Time.zone = nil
  end
end
