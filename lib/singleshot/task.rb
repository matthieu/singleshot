require 'singleshot/resource'

module Singleshot
  class Task < Resource

    class << self

      def validation_method(on)
        case on
          when :save   then :validate
          when :create then :validate_on_create
          when :update then :validate_on_update
          when :complete then :validate_on_complete
        end
      end

      def validate_on_complete(*methods, &block)
        methods << block if block_given?
        write_inheritable_set(:validate_on_complete, methods)
      end

      def data_fields(*attributes)
        write_inheritable_attribute(:data_fields, Set.new(attributes.map(&:to_s)) + (data_field_names || []))
        attributes.each do |attr_name|
          unless methods.include?(attr_name.to_s)
            define_method(attr_name) do
              if data = self.data
                data[attr_name.to_s]
              end
            end
          end
          unless methods.include?("#{attr_name}=")
            define_method("#{attr_name}=") do |value|
              self.data ||= {}
              self.data[attr_name.to_s] = value
            end
          end
        end
      end

      def data_field_names
        read_inheritable_attribute(:data_fields)
      end

    end

    attributes :id, :status, :updated_at, :title, :priority, :version, :cancellation, :due_on, :created_at, :data

    def complete
      errors.clear
      run_validations(:validate)
      validate
      run_validations(:validate_on_complete)
      validate_on_complete
      return false unless errors.empty?

      begin
        reload_from_response request(url, 'Accept'=>'application/json', 'Content-Type'=>'application/json',
                                           :method=>:post, :body=>attributes.to_json)
      rescue OpenURI::HTTPError=>ex
        map_error ex
      end
    end

    def complete!
      complete or raise ActiveRecord::RecordNotSaved
    end

    def validate_on_complete
    end

  end
end
