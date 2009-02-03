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

    # Expecting the named attribute to have the specified type and characteristics.
    # For example:
    #   it { should have_attribute(:name, :string, :null=>false) }
    #   it { should have_attribute(:quantity, :integer, :default=>1) }
    def have_attribute(name, type, other = {})
      simple_matcher("have attribute #{name} of type #{type}") { |given|
        column = given.column_for_attribute(name)
        column && column.type == type && other.all? { |key, value| other[key] == column.send(key) } }
    end

    # Expecting the model to use a locking column (default name is 'lock_version').
    def have_locking_column(name = 'lock_version')
      simple_matcher("have locking column #{name}") { |given| given.class.locking_enabled? && given.class.locking_column == name.to_s }
    end

    # Expecting the model to have a created_at timestamp attribute.
    def have_created_at_timestamp
      have_attribute :created_at, :datetime
    end

    # Expecting the model to have an updated_at timestamp attribute.
    def have_updated_at_timestamp
      have_attribute :updated_at, :datetime
    end

    # Expecting the model to have has_many association with the specified model, class and options.
    # For example:
    #   it { should have_many(:authors) }
    #   it { should have_many(:posts, Post) }
    #   it { should have_many(:comments, Comment, :dependent=>:delete_all) }
    def have_many(model, klass = nil, options = {})
      simple_matcher "have many #{model} #{klass && "(#{klass})"}" do |given, matcher|
        matcher.failure_message = "expected has_many :#{model}, #{options.merge(:class_name=>klass.name).inspect}"
        assoc = given.class.reflect_on_association(model.to_sym)
        if assoc && assoc.macro == :has_many
          matcher.failure_message << " but got has_many :#{model}, #{assoc.options.merge(:class_name=>assoc.klass.name).inspect}"
          (klass.nil? || assoc.klass <= klass) && options.all? { |key, value| options[key] == assoc.options[key] }
        else
          matcher.failure_message << " but no has_many :#{model} association found"
          false
        end
      end
    end

    # Expecting the model to have belongs_to association with the specified model, class and options.
    # For example:
    #   it { should belong_to(:author) }
    #   it { should belong_to(:post, Post) }
    def belong_to(model, klass = nil, options = {})
      simple_matcher "belong to #{model} #{klass && "(#{klass})"}" do |given, matcher|
        matcher.failure_message = "expected belongs_to :#{model}, #{options.merge(:class_name=>klass.name).inspect}"
        assoc = given.class.reflect_on_association(model.to_sym)
        if assoc && assoc.macro == :belongs_to
          matcher.failure_message << " but got belongs_to :#{model}, #{assoc.options.merge(:class_name=>assoc.klass.name).inspect}"
          (klass.nil? || assoc.klass <= klass) && options.all? { |key, value| options[key] == assoc.options[key] }
        else
          matcher.failure_message << " but no belongs_to :#{model} association found"
          false
        end
      end
    end

    # Expecting attribute value to look like a SHA1. For example:
    #   record.secret.should look_like_sha
    def look_like_sha
      simple_matcher('look like a SHA') { |given| given =~ /^[0-9a-f]{40}$/ }
    end

    # Expecting the named attribute to be accessible for mass assigning. For example:
    #   it { should allow_mass_assigning_of(:name) }
    def allow_mass_assigning_of(attr, new_value = 'new value')
      simple_matcher("allow mass assigning of #{attr}") { |given|
        (given.class.send(:accessible_attributes) || given.class.column_names).member?(attr.to_s) }
    end

    # Expecting the model to validate presence of the named attribute. For example:
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

    # Expecting the model to validate uniquness of the named attribute. For example:
    #   it { should validate_uniquness_of(:nickname) }
    def validate_uniquness_of(attr)
      simple_matcher "validate uniqueness of #{attr}" do |given|
        given.save!
        clone = given.clone
        !clone.valid? && clone.errors.on(attr)
      end
    end

    # Expecting the model to validate inclusion of the named attribute in the specified set.
    # The :not_in set helps assure the inclusion validation actually takes place. For example:
    #   it { should validate_inclusion_of(:status, :in=>[:active, :suspended, :completed], :not_in=>[:random] }
    def validate_inclusion_of(attr, options)
      inclusion = [options[:in] && "in #{options[:in].inspect}", options[:not_in] && "not in #{options[:not_in].inspect}"].compact.to_sentence
      simple_matcher "validate inclusion of #{attr} #{inclusion}" do |given, matcher|
        matcher.failure_message = "expected inclusion #{inclusion}"
        expect, all = options[:in], [options[:in], options[:not_in]].flatten.compact
        expect == all.select { |value| given.clone.update_attributes(attr=>value) }
      end
    end

  end
end

Spec::Runner.configure { |config| config.include Spec::Helpers::Models, :type=>:model }
