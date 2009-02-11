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
  # Validates that each attribute looks like a valid e-mail address.  Does not check that the
  # e-mail address makes sense, only that it is more likely to be an e-mail address than a phone number.
  #
  # For example:
  #   validates_email :email
  module Email
    
    def self.included(mod)
      I18n.backend.store_translations :'en-US',
        { :active_record => { :error_messages => { :invalid_email => "is not a valid email address" } } }
  
      mod.class_eval do

        # Validates that each attribute looks like a valid e-mail address.  Does not check that the
        # e-mail address makes sense, only that it is more likely to be an e-mail address than a phone number.
        def self.validates_email(*attr_names)
          configuration = { :on => :save }
          configuration.update(attr_names.extract_options!)
          configuration[:with] = /^([^@\s]+)@[-a-z0-9]+(\.[-a-z0-9]+)*$/
          configuration[:message] ||= I18n.translate('active_record.error_messages.invalid_email')
          attr_names << configuration
          validates_format_of *attr_names
        end

      end
    end

  end
end
