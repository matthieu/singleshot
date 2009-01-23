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


require File.dirname(__FILE__) + '/../spec_helper'


# These helper methods and matchers are available only when speccing AR models.
module Spec::Helpers #:nodoc:
  module Models

    # Checks that the subject has an attribute with the specified type and characteristics.
    # For example:
    #   should have_attribute(:name, :string, :null=>false)
    #   should have_attribute(:quantity, :integer, :default=>1)
    def have_attribute(name, type, other = {})
      simple_matcher("have attribute #{name} of type #{type}") { |given|
        column = given.column_for_attribute(name)
        column && column.type == type && other.all? { |key, value| other[key] == column.send(key) } }
    end
 
    # Checks that the named locking column is used (default to 'lock_version').
    def have_locking_column(name = 'lock_version')
      simple_matcher("have locking column #{name}") { |given| given.class.locking_enabled? && given.class.locking_column == name.to_s }
    end

    # Checks that the record has a created_at timestamp attribute.
    def have_created_at_timestamp
      have_attribute :created_at, :datetime
    end

    # Checks that the record has an updated_at timestamp attribute.
    def have_updated_at_timestamp
      have_attribute :updated_at, :datetime
    end

    # Checks that the attribute looks like a SHA1. For example:
    #   record.secret.should look_like_sha1
    def look_like_sha1
      simple_matcher('look like a SHA1') { |given| given =~ /^[0-9a-f]{40}$/ }
    end

    # Check that model allows mass assigning of the specified attribute. For example:
    #   it { should allow_mass_assigning_of(:name) }
    def allow_mass_assigning_of(attr, new_value = 'new value')
      simple_matcher("allow mass assigning of #{attr}") { |given|
        given.class.send(:accessible_attributes).member?(attr.to_s) }
    end

    # Check that model validates presence of an attribute. For example:
    #   it { should validate_presence_of(:email) }
    def validate_presence_of(attr)
      simple_matcher "validate presence of #{attr}" do |given|
        begin
          original = given.attributes[attr]
          given.attributes = { attr=>nil }
          !given.valid? && given.errors.on(attr)
        ensure
          given.attributes = { attr => original }
        end
      end
    end

    # Checks that the model validates uniqueness of an attribute. As a side effect it
    # stores a clone of the record and then attempts to save the record itself.
    # For example:
    #   it { should validate_uniquness_of(:nickname) }
    def validate_uniquness_of(attr)
      simple_matcher "validate uniqueness of #{attr}" do |given|
        given.clone.save!
        !given.valid? && given.errors.on(attr)
      end
    end

  end
end

Spec::Runner.configure { |config| config.include Spec::Helpers::Models, :type=>:model }
