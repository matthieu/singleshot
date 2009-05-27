module Presenter
  class Base
    
    class << self
      # Object name, derived from the class name (e.g. TaskPresenter becomes 'task').
      # Used for the accessor method name and XML document element name, so TaskPresenter
      # will have a method #task to access the current task (alias of #object), and
      # XML documents would have +<task>+ as the document element.
      attr_reader :object_name

      def inherited(klass)
        object_name = klass.name.demodulize.sub(/Presenter$/, '').underscore
        klass.instance_variable_set(:@object_name, object_name)
        klass.class_eval "alias #{object_name} object"
      end
      
    end

    # Creates new presenter using the given controller and object/array.
    def initialize(controller, object, options = {})
      @controller = controller
      @object = object
      @options = options
    end

    include PresentingMethod
    
    # Controller associated with this presenter. Used primarily to create URLs
    # and access various helper methods.
    attr_reader :controller

    # Object being presented. Can also be accessed from named attribute,
    # e.g. the #task method on TaskPresenter.
    attr_reader :object

    # Options for presenting the object.
    attr_reader :options

    # Converts to JSON document, returns a String.  The default implementation
    # uses #map to convert the instance or each member of the array, and calls
    # #to_json on the result.
    #
    # For example:
    #   render :json=>presenting(@item)
    def to_json(json_options = {})
      root = options[:name] || self.class.object_name
      { root=>to_hash }.to_json(json_options)
    end

    # Converts to XML document, returns a String.  The default implementation
    # uses #map to convert the instance or each member of the array, and calls
    # #to_xml on the result.
    #
    # For example:
    #   render :xml=>presenting(@items)
    def to_xml(xml_options = {})
      root = options[:name] || self.class.object_name
      to_hash.to_xml({:root=>root.to_s}.merge(xml_options))
    end
    
  protected
  
    # Shortcut for CGI::escapeHTML.
    def h(text)
      CGI::escapeHTML(text)
    end

    include ActionController::UrlWriter, ActionController::PolymorphicRoutes
    # TODO: do we need this?
    # default_url_options[:host] = 'test.host' if defined?(RAILS_ENV) && RAILS_ENV == 'test'
=begin
    def url_for_with_controller(*args)
      if controller
        controller.url_for(*args)
      else
        url_for_without_controller(*args)
      end
    end
    alias_method_chain :url_for, :controller
    def url_for(options = {})
      controller.url_for(options)
    end
=end
    
    def href
      polymorphic_url(object)
    end

    # Request to which this controller is responding.
    #def request
    #  controller && controller.request
    #end
    
    # Converts object into a hash.  JSON, XML and other output formats use this
    # before serializing the result into the respective content type.
    #
    # Override to do all sorts of fancy tricks.  The defult implementation calls
    # the attributes methods (works on ActiveRecord models), lacking that the to_hash
    # method, and if neither is found return an empty hash.
    def to_hash
      returning 'gid'=>gid do |hash|
        hash.update(object.to_hash) if object.respond_to?(:to_hash)
        yield hash if block_given?
      end
    end

    def gid
      gid_for(object)
    end
    
    # Returns an ID using the host name, object class and object identifier.
    def gid_for(object)
      "tag:#{self.class.default_url_options[:host]},#{object.created_at.year}:#{self.class.object_name}/#{object.id}"
    end

    def link_to(rels, url_options, options = {})
      { :rel=>Array(rels).join(' '), :href=>url_options }.merge(options.slice(:title, :type))
    end

    def action(name, url_options, *args)
      url = url_options.kind_of?(String) ? url_options : url_for(url_options)
      options = args.extract_options!
      method = args.shift || 'post'
      { :name=>name, :url=>url, :method=>method }.merge(options.slice(:method, :title, :enctype))
    end
  end
end
