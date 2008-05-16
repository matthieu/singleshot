# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  helper :all # include all helpers, all the time


  # --- Authentication ---

  # Turn sessions off for everything but HTML and AJAX.  This also forces HTTP Basic Authentication
  # on all other type of requests (JSON, iCal, etc).
  session :off, :if=>lambda { |req| !(req.format.html? || req.xhr?) }

  before_filter :authenticate

  # Authentication filter, added by default on all actions in all controllers.
  # Uses HTTP Basic Authentication or, when processing HTML/AJAX requests, sessions.
  def authenticate
    return if @authenticated
    if ActionController::HttpAuthentication::Basic.authorization(request) || !session_enabled?
      authenticate_or_request_with_http_basic request.domain do |login, password|
        @authenticated = Person.authenticate(login, password)
      end
    else
      @authenticated ||= Person.find(session[:person_id]) rescue nil
      unless @authenticated
        flash[:return_to] = request.url
        redirect_to session_url
      end
    end
  end

  def self.access_key_authentication(options = {})
    formats = options[:formats] || ['atom', 'ics']
    options[:if] ||= lambda { |controller| formats.include?(controller.request.format) }
    prepend_before_filter :authenticate_with_access_key, options
  end

  # Access key authentication, used for feeds, iCal and other type of requets that
  # do not support HTTP authentication or sessions.  Can only be used for GET requests.
  #
  # To apply as a filter (must come before authenticate):
  #   prepend_before_filter :authenticate_with_access_key, :only=>[:feed]
  def authenticate_with_access_key
    raise ActionController::MethodNotAllowed, 'GET' unless request.get?
    @authenticated = Person.find_by_access_key(params[:access_key]) or raise ActiveRecord::RecordNotFound
  end

  # Raise to return 403 (Forbidden) with optional error message.
  class NotAuthorized < Exception
  end
  rescue_responses[NotAuthorized.name] = :forbidden

  # Returns Person object for currently authenticated user.
  attr_reader :authenticated


  # --- Authenticated user ---

  # Returns language code for currently authenticated user (may be nil).
  def language
    authenticated.language
  end

  # TODO: Add timezone support when upgrading to Rails 2.1.

end
