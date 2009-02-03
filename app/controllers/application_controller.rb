# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  helper :all # include all helpers, all the time

  def index
    redirect_to tasks_url
  end

protected

  # --- Authentication/Security ---

  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '{secret}}'

  before_filter :authenticate

  # Authentication filter enabled by default since most resources are guarded.
  def authenticate
    # Good luck using HTTP Basic/sessions with feed readers and calendar apps.
    # Instead we use a query parameter tacked to the URL to authenticate, and
    # given the lax security, only for these resources and only for GET requests.
    if params[:access_key] && (request.format.atom? || request.format.ics?)
      raise ActionController::MethodNotAllowed, 'GET' unless request.get?
      session.data.clear # don't send back cookies
      @authenticated = Person.find_by_access_key(params[:access_key])
      head :forbidden unless @authenticated
    else
      # Favoring HTTP Basic over sessions makes my debugging life easier.
      if ActionController::HttpAuthentication::Basic.authorization(request)
        @authenticated = authenticate_or_request_with_http_basic(request.host) { |login, password| Person.authenticate(login, password) }
        session.data.clear
      else
        @authenticated = Person.find(session[:person_id]) rescue nil
        unless @authenticated
          # Browsers respond favorably to this test, so we use it to detect browsers
          # and redirect the use to a login page.  Otherwise we assume dumb machine and
          # insist on HTTP Basic.
          if request.format.html?
            flash[:return_to] = request.url
            redirect_to session_url
          else
            session.data.clear
            request_http_basic_authentication
          end
        end
      end
    end
  end
  

  # --- Authenticated user ---

  # Returns Person object for currently authenticated user.
  attr_reader :authenticated

  # Returns language code for currently authenticated user (may be nil).
  def language
    authenticated.language if authenticated
  end

  # Set time zone for currently authenticated user.
  before_filter do |controller|
    Time.zone = controller.authenticated.timezone rescue nil
  end
  
end
