# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with this
# work for additional information regarding copyright ownership.  The ASF
# licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.


module Validators #:nodoc:
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
  module Url

    def self.included(mod)
      I18n.backend.store_translations :'en-US',
        { :active_record => { :error_messages => { :invalid_url => "is not a valid URL" } } }
      mod.class_eval do

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
          configuration = { :on=>:save, :schemes=>['http', 'https'] }
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
            message = record.errors.generate_message(attr_name, :invalid_url, :default=>configuration[:message])
            record.errors.add attr_name, message unless uri && uri.scheme && uri.host &&
              configuration[:schemes].include?(uri.scheme.downcase)
          end
        end

      end
    end

  end
end
