module Singleshot
  class Resource

    cattr_accessor :logger, :instance_writer => false
    cattr_accessor :new_url, :instance_writer => false

    class << self

      def reference(url)
        returning(new) do |instance|
          instance.url = url
        end
      end

      def load(url)
        reference(url).reload
      end

      def create(attributes = {})
        new(attributes).save
      end

      def create!(attributes = {})
        new(attributes).save!
      end

      def attributes(*attributes)
        write_inheritable_attribute(:attributes, Set.new(attributes.map(&:to_s)) + (attribute_names || []))
        attributes.each do |attr_name|
          unless methods.include?(attr_name.to_s)
            define_method(attr_name) { self[attr_name] }
          end
          unless methods.include?("#{attr_name}=")
            define_method("#{attr_name}=") { |value| self[attr_name] = value }
          end
        end
      end

      def attribute_names
        read_inheritable_attribute(:attributes)
      end

      def human_attribute_name(attribute)
        attribute.humanize
      end

    end

    def initialize(attributes = {})
      @attributes = {}
      self.attributes = attributes if attributes
    end

    attr_accessor :url

    def new_record?
      url.nil?
    end

    def [](name)
      @attributes[name.to_s]
    end

    def []=(name, value)
      @attributes[name.to_s] = value
    end

    def attributes=(attributes)
      attributes.each do |name, value|
        send "#{name}=", value
      end
    end

    def attributes
      self.class.attribute_names.inject({}) { |hash, name| hash.update(name=>send(name)) }
    end

    def reload
      begin
        reload_from_response request(url, 'Accept'=>'application/json', :method=>:get)
        self
      rescue OpenURI::HTTPError=>ex
        raise ActiveRecord::RecordNotFound, ex.message
      end
    end

    def save
      new_record? ? create : update
    end

    def save!
      save or raise ActiveRecord::RecordNotSaved
    end

    def update_attribute(name, value)
      send "#{name}=", value
      save
    end

    def update_attribute!(name, value)
      send "#{name}=", value
      save!
    end

    include ActiveRecord::Validations

  private

    def create
      begin
        response = request(new_url, 'Accept'=>'application/json', 'Content-Type'=>'application/json',
                                    :method=>:post, :body=>attributes.to_json)
        # TODO: need more handling for response type
        reload_from_response response, response['Location']
      rescue OpenURI::HTTPError=>ex
        map_error ex
      end
    end

    def update
      begin
        reload_from_response request(url, 'Accept'=>'application/json', 'Content-Type'=>'application/json',
                                          :method=>:put, :body=>attributes.to_json)
      rescue OpenURI::HTTPError=>ex
        map_error ex
      end
    end

    def reload_from_response(response, url = response.base_uri)
      json = ActiveSupport::JSON.decode(response)
      self.class.attribute_names.each { |name| send "#{name}=", json[name] }
      true
    end

    def map_error(exception)
      body = exception.io.read
      if body.blank?
        errors.add_to_base exception.message
      else
        errors.add_to_base body
      end
      false
    end

    def request(url, options = {})
      uri = URI(url.to_s)
      raise ActiveRecord::RecordNotFound, 'Only HTTP(S) URLs allowed' unless uri.scheme =~ /^http(s?)$/i
      raise ActiveRecord::RecordNotFound, 'Must be an absolute URL' unless uri.absolute?
      uri.normalize!
      uri.scheme = uri.scheme.downcase
      options[:http_basic_authentication] = [uri.user, uri.password] if uri.user
      uri.read(options)
    end

  end
end
