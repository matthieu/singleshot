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

=begin
    # Returns the currently authenticated person.
    def authenticated
      Person.find(session[:authenticated]) if session[:authenticated] 
    end

    # Returns true if the previous request was authenticated and authorized.
    def authorized?
      !(response.redirected_to == session_url || response.code == '401')
    end
=end
  end
end

Spec::Runner.configure { |config| config.include Spec::Helpers::Controllers, :type=>:controller }
