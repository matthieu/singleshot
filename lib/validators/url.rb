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


module Validators::Url #:nodoc:

  def self.included(base) #:nodoc:
    base.extend ClassMethods
  end

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
        unless uri && uri.scheme && uri.host && configuration[:schemes].include?(uri.scheme.downcase)
          record.errors.add attr_name, configuration[:message] || :invalid_url
        end
      end
    end

  end

  if defined?(Spec::Matchers)
    # RSpec validation expectation. Expects validation on all named attributes,
    # or <code>:url</code> if no attribute named. For example:
    #   it { should validate_url }
    #   it { should validate_url(:site_url) }
    module Matchers
      Spec::Matchers.create :validate_url do |*attrs|
        attrs = [:url] if attrs.empty?
        match do |subject|
          values = %w{example.com http-example.com http://example.com ftp://example.com}
          validated = values.map { |value|
            attrs.all? { |attr|
              old = subject.send(attr)
              begin
                subject.send "#{attr}=", value
                subject.valid? || !subject.errors.on(attr)
              ensure
                subject.send "#{attr}=", old
              end
            }
          }
          validated == [false, false, true, false]
        end
      end
    end
  end

end
