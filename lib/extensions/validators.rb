module ActiveRecord
  module Validators
    module Url

      def self.included(mod)
        ActiveRecord::Errors.default_error_messages[:invalid_url] = 'Not a valid URL'
        mod.extend ClassMethods
      end

      module ClassMethods
 
        # Validates that each attribute is a URL and also normalizes the URL before saving it.
        #
        # The URL is checked to be valid, include a schema and host name (and therefore be absolute),
        # and only uses an allowed scheme.  The allowed schemes are specified by the :schemes option,
        # defaulting to HTTP and HTTPS.  The normalized URL has its scheme in all lower case, and so
        # should the names passed to :scheme.
        #
        # For example:
        #   # Only allow HTPS
        #   validates_url :secure_url, :schemes=>['https']
        def validates_url(*attr_names)
          configuration = { :message => ActiveRecord::Errors.default_error_messages[:invalid_url], :on=>:save,
                            :schemes=>['http', 'https'] }
          configuration.update(attr_names.extract_options!)

          # Normalize URL.
          before_validation do |record|
            attr_names.each do |attr_name|
              url = record.send(attr_name) 
              if url && uri = URI(url) rescue nil
                uri.normalize!
                uri.scheme = uri.scheme.downcase if uri.scheme
                record.send "#{attr_name}=", uri.to_s
              end
            end
          end

          # Validate URL.
          validates_each(attr_names, configuration) do |record, attr_name, value|
            uri = URI.parse(value) rescue nil
            record.errors.add attr_name, configuration[:message] unless uri && uri.scheme && uri.host &&
              configuration[:schemes].include?(uri.scheme.downcase)
          end
        end

      end

    end

    module Email

      def self.included(mod)
        ActiveRecord::Errors.default_error_messages[:invalid_email] = 'Not a valid e-mail address'
        mod.extend ClassMethods
      end
     
      module ClassMethods

        # Validates that each attribute looks like a valid e-mail address.  Does not check that the
        # e-mail address makes sense, only that it is more likely to be an e-mail address than a phone number.
        def validates_email(*attr_names)
          configuration = { :message => ActiveRecord::Errors.default_error_messages[:invalid_email], :on => :save }
          configuration.update(attr_names.extract_options!)
          configuration.update(:with => /^([^@\s]+)@[-a-z0-9]+(\.[-a-z0-9]+)*$/)
          attr_names << configuration
          validates_format_of *attr_names
        end

      end

    end
  
  end

end
