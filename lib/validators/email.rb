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
  # Validates that each attribute looks like a valid e-mail address.  Does not check that the
  # e-mail address makes sense, only that it is more likely to be an e-mail address than a phone number.
  #
  # For example:
  #   validates_email :email
  module Email
   
    # Included in ActiveRecord::Base.
    def self.included(mod)
      I18n.backend.store_translations 'en-US',
        { :active_record => { :error_messages => { :invalid_email => "is not a valid email address" } } }
  
      mod.class_eval do

        # Validates that each attribute looks like a valid e-mail address.  Does not check that the
        # e-mail address makes sense, only that it is more likely to be an e-mail address than a phone number.
        def self.validates_email(*attr_names)
          configuration = { :on => :save }
          configuration.update(attr_names.extract_options!)
          configuration[:with] = /\A([^@\s]+)@[-a-z0-9]+(\.[-a-z0-9]+)*\z/
          configuration[:message] ||= I18n.translate('active_record.error_messages.invalid_email')
          attr_names << configuration
          validates_format_of *attr_names
        end

      end
    end

  end
end
