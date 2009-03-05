module Presenter 
  module PresentingMethod

    # Return a new presenter. This method can be called in several configurations to
    # present both an instance and an array:
    #
    # You can call this method in several configurations to present both singular objects
    # and arrays. Using an explicit type followed by value:
    #   presenting(class, object_or_array)
    # The first argument specifies the expected type of the object/array that follows,
    # and that argument is used to find the presenter class. For example, <tt>presenting(Foo,[])<tt>
    # uses <tt>FooPresenter</tt>.
    #   presenting(symbol, object_or_array)
    # This method is similar but replaces explicit class with symbol, so <tt>foo:<tt> instead
    # of <tt>Foo</tt>.
    #   presenting(object)
    # The third form takes a single argument and finds the presenter class based on the
    # argument type, for example, <tt>presenting(Foo.new)</tt> will use the presenter class
    # <tt>FooPresenter</tt>.
    #   presenting(array)
    # Since arrays may be empty it is not always possible to use the array content to figure
    # out the presenter class. Either specify it explicitly as the first argument (see above),
    # or let the presenting method figure it out from the controller name, for example,
    # inferring <tt>FooPresenter</tt> from <tt>FooController</tt>.
    def presenting(*args)
      controller = ActionController::Base === self ? self : self.controller
      case args.first
      when Class    # Presented class followed by instance/array
        name = args.shift.to_s
        value = args.shift
      when Symbol   # Presenter name (symbol) followed by instance/array
        name = args.shift.to_s.classify
        value = args.shift
      when Array    # Array of values, pick presenter from item type
        value = args.shift
        name = 'Array'
      else          # Presenter for single instance.
        value = args.shift
        name = value.class.name
      end
      options = args.shift || {}
      raise ArgumentError, "Unexpected arguments #{args.inspect}" unless args.empty?
      Class.const_get("#{name}Presenter").new(controller, value, options)
    end

    def present(object, options = {})
      respond_with presenting(object, options), options
    end

  end
end

ActionController::Base.class_eval do
  protected
  include Presenter::PresentingMethod
end
ActionView::Base.class_eval do
  protected
  include Presenter::PresentingMethod
end
