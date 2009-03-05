module Presenter #:nodoc:

  # Use the #respond_to and #respond_with methods to simplify responses with multiple content types.
  #
  # For example:
  # class PostsController < ApplicationController
  #   respond_to :html, :json, :xml
  #
  #   def show
  #     respond_with Post.find(params[:id])
  #   end
  # end
  module Responding

    def self.included(base) #:nodoc:
      base.class_eval do
        extend ClassMethods
        class_inheritable_reader :formats_for_respond_to
      end
    end

    module ClassMethods
      # Tell the controller which content types we support, for use with respond_with. For example:
      #   respond_to :html, :json, :xml
      def respond_to(*formats)
        formats.map!{ |format| format.to_sym }
        write_inheritable_array(:formats_for_respond_to, formats)
      end
    end

    # Respond with object using any appropriate content type. Content types are specified for all
    # actions using respond_to, or specifically for this action using the <pre>:to</pre> option.
    #
    # This method responds by finding an appropriate view using the action name, or value of
    # <pre>:action</pre> option. If it cannot find a suitable template, it attempts to call a
    # <pre>to_[format]</pre> method on the object, e.g. <pre>to_json</pre> or <pre>to_xml</pre>.
    #
    # All other options are passed as is to the #render method.
    #
    # For example:
    #   respond_with @posts
    #   respond_with @events, :to=>[:html, :ics]
    #   respond_with @results, :action=>'index'
    #   respond_with @post, :status=>:created, :location=>@post
    def respond_with(object, options = {})
      if options[:to]
        mime_types = Array(options.delete(:to))
        mime_types.map!{ |mime| mime.to_sym }
      else
        mime_types = formats_for_respond_to
      end
      format = request.format.to_sym

      if mime_types.include?(format)
        response.template.template_format = format
        response.content_type = request.format.to_s #=> "text/html"
        
        template = default_template(options.delete(:action) || action_name) rescue nil
        if template
          render options.merge(:template=>template)
        elsif object.respond_to?("to_#{format}")
          render options.except(:layout).merge(:text=>object.send("to_#{format}"))
        elsif request.format.html? && (request.post? || request.put?)
          redirect_to options[:location] || options[:redirect_to], :status=>:see_other
        else
          render options.merge(:text=>'404 Not Found', :status=>404)
        end
      else
        head :not_acceptable
      end
    end
  end
end

ActionController::Base.class_eval do
  protected
  include Presenter::Responding
end
