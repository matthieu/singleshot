module Presenter::ReadableAttributes
  class << self
    def included(mod)
      mod.extend ClassMethods
    end
  end

  module ClassMethods
    def attr_readable(*attributes)
      write_inheritable_attribute(:attr_readable, Set.new(attributes.map(&:to_s)) + (readable_attributes || []))
    end

    def readable_attributes
      read_inheritable_attribute(:attr_readable)
    end

    def to_hash_attribute_names #:nodoc:
      @to_hash_attribute_names ||= readable_attributes || accessible_attributes || (column_names - [primary_key])
    end
  end

  def to_hash
    self.class.to_hash_attribute_names.inject({}) do |hash, attr|
      value = send(attr)
      if value.respond_to?(:to_hash)
        value = value.to_hash
      elsif value === Array
        value = value.map { |i| i.respond_to?(:to_hash) ? i.to_hash : i }
      end
      hash[attr.to_s] = value unless value.nil?
      hash
    end
  end
  
end

ActiveRecord::Base.class_eval do
  include Presenter::ReadableAttributes
end
