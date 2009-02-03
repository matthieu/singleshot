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


# == Schema Information
# Schema version: 20090121220044
#
# Table name: people
#
#  id         :integer         not null, primary key
#  identity   :string(255)     not null
#  fullname   :string(255)     not null
#  email      :string(255)     not null
#  language   :string(5)
#  timezone   :integer(4)
#  password   :string(255)
#  access_key :string(40)      not null
#  created_at :datetime
#  updated_at :datetime
#


require 'sha1'
require 'openssl'

# Internally we keep a primary key association between the person and various other records.
# Externally, we use a public identifier returned from #to_param and resolved with Person.identify.
# The base implementation uses the person's nickname (derived from e-mail address) as the public identifier.
#
# In addition, we need to know the person's full name for presentation and e-mail address for
# sending notifications.  Language and timezone (in minutes relative to UTC) are optional,
# although it is highly recommended to set the timezone.
#
# Passwords are optional, since not every one requires password authentication (may use OpenID,
# or some other authentication mechanism).  We use BCrype to store passwords securely.
#
# The access_key field is used for authentication when sessions and HTTP Basic are not possible,
# for example, to access feeds and iCal.
class Person < ActiveRecord::Base

  class << self

    # Resolves a person based on their identity.  For convenience, when called with a Person object,
    # returns that same object. You can also call this method with an array of identities, and
    # it will return an array of people.  Matches against the identity returned in to_param.
    def identify(identity)
      case identity
      when Person then identity
      when Array then Person.all(:conditions=>{:identity=>identity.flatten.uniq})
      else Person.find_by_identity(identity.to_s) or raise ActiveRecord::RecordNotFound
      end
    end

    # Used for identity/password authentication.  Return the person if authenticated.
    def authenticate(identity, password)
      person = Person.find_by_identity(identity)
      person if person && person.authenticated?(password)
    end

  end

  has_many :activities, :dependent=>:delete_all
  has_many :stakeholders, :dependent=>:delete_all

  attr_accessible :identity, :fullname, :email, :language, :timezone, :password

  def initialize(*args)
    super
  end

  # Returns an identifier suitable for use with Person.resolve.
  def to_param
    identity
  end

  def same_as?(person)
    person == (person.is_a?(Person) ? self : to_param)
  end

  # Must have identity.
  validates_uniqueness_of :identity, :message=>'A person with this identity already exists.'

  # Must have e-mail address.
  validates_email         :email, :message=>"I need a valid e-mail address."
  validates_uniqueness_of :email, :message=>'This e-mail is already in use.'

  before_validation do |record|
    record.email = record.email.to_s.strip.downcase
    record.identity = record.email.to_s.strip[/([^\s@]*)/, 1].downcase if record.identity.blank?
    record.identity = record.identity.strip.gsub(/\s+/, '_').downcase
    record.fullname = record.email.to_s.strip[/([^\s@]*)/, 1].split(/[_.]+/).map(&:capitalize).join(' ') if record.fullname.blank?
    record.fullname = record.fullname.strip.gsub(/\s+/, ' ')
  end

  def url
    read_attribute(:identity)
  end

  # Sets a new password.
  def password=(value)
    salt = SHA1.hexdigest(OpenSSL::Random.random_bytes(128))[0,10]
    crypted = SHA1.hexdigest("#{salt}:#{value}")
    super "#{salt}:#{crypted}"
  end

  # Authenticate against the supplied password.
  def authenticated?(against)
    return false unless password
    salt, crypted = password.split(':')
    crypted == SHA1.hexdigest("#{salt}:#{against}")
  end

  # Sets a new password for this person and returns the password in clear text.
  def new_password!
    self.password = Array.new(10) { (65 + rand(58)).chr }.join
  end

  # Sets a new access key for this person. Access key is read-only and this is the only way
  # to change it, for example, if the previous access key has been compromised. Returns the
  # new access key.
  def new_access_key!
    self.access_key = SHA1.hexdigest(OpenSSL::Random.random_bytes(128))
  end

  before_save do |record| 
    record.new_access_key! unless record.access_key
  end


  # Use this instead of update_attributes to update a task, subject to this person's
  # role in the task. It will check that this person is associated with the task, and
  # based on their role, which changes are allowed, and finally record an activity for
  # that person.
  #
  # Saves the record and returns true if successful. You can query task#errors for
  # a list of validation and authorization errors.
  #
  # For example:
  #   supervisor.udpate_task task, :status=>:cancel
  def update_task(task, attributes)
    if attributes[:owner] && attributes[:owner] != task.owner && !task.in_role?(:supervisor, self)
      task.errors.add :owner, "Only owner or supervisor can change ownership" unless task.owner.nil? || task.in_role?(:owner, self)
      task.errors.add :owner, "Potential owners can only assign task to themselves" unless task.in_role?(:potential_owner, attributes[:owner])
    end

    task.attributes = attributes

    # Check authorization to state changes.
    if task.status_changed?
      task.errors.add :status, "Only supervisor is allowed to resume this task" if task.status_was == 'suspended' && !task.cancelled? && !task.in_role?(:supervisor, self)
      case task.status
      when 'suspended'
        task.errors.add :status, "Only supervisor is allowed to suspend this task" unless task.in_role?(:supervisor, self)
      when 'completed'
        task.errors.add :status, "Only owner can complete task" unless task.owner == self
      #when 'cancelled'
        #task.errors.add :status, "Only supervisor allowed to cancel this task" unless task.in_role?(:supervisor, self)
      end
    end

    task.errors.empty? && task.save
  end

  # Similar to #update_task, but raises ActiveRecord::InvalidRecord in case of error.
  def update_task!(task, attributes)
    update_task(task, attributes) or raise ActiveRecord::InvalidRecord, task
  end

end
