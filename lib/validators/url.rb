# Singleshot  Copyright (C) 2008-2009  Intalio, Inc
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


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

    # Included in ActiveRecord::Base.
    def self.included(mod)
      I18n.backend.store_translations 'en-US',
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
        def self.validates_url(*attr_names)
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
