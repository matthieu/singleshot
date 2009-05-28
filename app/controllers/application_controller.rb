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


class ApplicationController < ActionController::Base #:nodoc:

  helper :all # include all helpers, all the time

protected

  # --- Authentication/Security ---

  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password

  # All requests authenticated unless said otherwise. This filter must run before CSRF protection.
  prepend_before_filter :authenticate

  # See ActionController::RequestForgeryProtection for details
  protect_from_forgery

  # Returns currently authenticated user.
  attr_reader :authenticated
  
  # Authentication filter enabled by default since most resources are guarded.
  def authenticate
    # Good luck using HTTP Basic/sessions with feed readers and calendar apps.
    # Instead we use a query parameter tacked to the URL to authenticate, and
    # given the lax security, only for these resources and only for GET requests.
    if params[:access_key] && (request.format.atom? || request.format.ics?)
      raise ActionController::MethodNotAllowed, 'GET' unless request.get?
      reset_session # don't send back cookies
      @authenticated = Person.find_by_access_key(params[:access_key])
      head :forbidden unless @authenticated
    else
      # Favoring HTTP Basic over sessions makes my debugging life easier.
      if ActionController::HttpAuthentication::Basic.authorization(request)
        authenticate_or_request_with_http_basic(request.host) do |login, password|
          @authenticated = Person.authenticate(login, password)
        end
        reset_session
        params[request_forgery_protection_token] = form_authenticity_token
      else
        @authenticated = Person.find(session[:authenticated]) rescue nil
        unless @authenticated
          # Browsers respond favorably to this test, so we use it to detect browsers
          # and redirect the use to a login page.  Otherwise we assume dumb machine and
          # insist on HTTP Basic.
          if request.format.html?
            session[:return_url] = request.url
            redirect_to session_url
          else
            reset_session
            request_http_basic_authentication
          end
        end
      end
    end
    if @authenticated
      I18n.locale = @authenticated.locale.to_sym if @authenticated.locale
      Time.zone = @authenticated.timezone
    end
  end

  helper_method :sidebar
  def sidebar
    ApplicationHelper::Sidebar.new @activities, @templates, @notifications
  end

end
