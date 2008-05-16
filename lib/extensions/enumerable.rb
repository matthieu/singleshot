module ActiveRecord
  module Enumerable

    def self.included(mod)
      mod.extend ClassMethods
    end

    module ClassMethods

      # Handles the named attribute as enumeration using the specified symbols.
      # For example:
      #   enumerable :state, [:open, :closed, :cancelled], :check_methods=>true
      # Allows:
      #   record.state = :open
      #   record.state
      #   => :open
      #   record.state_before_typecast
      #   => 0
      #   record.open?
      #   => true
      #   Record::STATES
      #   => [:open, :closed, :cancelled]
      #   Record.state(:closed)
      #   => 1
      # 
      # Allowed options:
      # * :constant -- Specifies the constant that will hold the enumerated symbols,
      #   or false to not create a constant.  The default behavior uses the pluralized
      #   name of the attribute.
      # * :default  -- Specifies a default value to apply to the attribute, otherwise,
      #   attributes with no specified value return nil.
      # * :check_methods -- If true, adds a check method for each enumerated value,
      #   for example, open? to return true if status == :open.
      # * :validates -- Unless false, adds validates_inclusion_of rule.
      def enumerable(attr_name, *args)
        options = args.extract_options!
        symbols = args.flatten
        # Define constant, if not already defined.
        case options[:constant]
        when false
        when nil
          const_name = attr_name.to_s.pluralize.upcase
          const_get(const_name) rescue const_set const_name, symbols
        else
          const_set options[:constant].to_s.upcase, symbols
        end
        # Read/write methods.
        define_method attr_name do
          if value = read_attribute(attr_name)
            symbols[value]
          elsif value = options[:default]
            write_attribute attr_name, symbols.index(value)
            value
          end
        end
        define_method "#{attr_name}=" do |value|
          write_attribute attr_name, symbols.index(value ? value.to_sym : options[:default])
        end
        # Class method to convert symbol into index.
        class << self ; self ; end.instance_eval do
          define_method(attr_name) { |symbol| symbols.index(symbol) }
        end
        # Validation.
        unless options[:validate] == false
          condition = options[:condition] || lambda { |record| record.send(attr_name) }
          validates_inclusion_of attr_name, :in=>symbols, :if=>condition,
            :message=>options[:message] || "Allowed values for attribute #{attr_name} are #{symbols.to_sentence}"
        end
        # Check methods (e.g. foo?, bar?).
        if options[:check_methods]
          symbols.each do |symbol|
            define_method("#{symbol}?") { send(attr_name) == symbol }
          end
        end
      end

    end
  end
end
