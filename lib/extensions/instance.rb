module ActionController
  module Instance
    def self.included(mod)
      mod.extend ClassMethods
    end

    module ClassMethods
      def instance(*args)
        options = args.extract_options!
        symbol = (args.shift || self.name.demodulize.gsub(/Controller$/, '').underscore).to_sym
        ivar = "@#{symbol}".to_sym
        # Define method to retrieve instance value, add as helper.
        define_method(name) { instance_variable_get(ivar) }
        protected name
        helper_method name
        # Protected method instance() retrieves the current instance of looks it up.
        cls = symbol.to_s.classify.constantize
        define_method(:instance) { instance_variable_get(ivar) || instance_variable_set(ivar, cls.find(params['id'])) }
        protected :instance
        # Create before_filter using only/except/if options.  Optional check runs on found instance.
        if check = options.delete(:check)
          if check.is_a?(Symbol)
            method = check
            filter = lambda do |controller|
              instance = controller.send(:instance)
              controller.send(check, instance) or raise ActiveRecord::RecordNotFound
            end
          else
            raise ArgumentError, 'The :check option must be a symbol, method or proc' unless check.respond_to?(:call)
            filter = lambda do |controller|
              instance = controller.send(:instance)
              check.call(controller, instance) or raise ActiveRecord::RecordNotFound
            end
          end
          before_filter filter, options
        else
          before_filter :instance, options
        end
      end
    end
  end
end
