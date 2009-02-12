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
#
#
# == Schema Information
# Schema version: 20090206215123
#
# Table name: people
#
#  id         :integer         not null, primary key
#  identity   :string(255)     not null
#  fullname   :string(255)     not null
#  email      :string(255)     not null
#  locale     :string(5)
#  timezone   :integer(4)
#  password   :string(64)
#  access_key :string(32)      not null
#  created_at :datetime
#  updated_at :datetime
#
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


  def initialize(*args)
    super
  end

  has_many :activities, :dependent=>:delete_all
  has_many :stakeholders, :dependent=>:delete_all

  attr_accessible :identity, :fullname, :email, :locale, :timezone, :password
  symbolize :locale

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
    return super if value.nil?
    salt = ActiveSupport::SecureRandom.hex(5)
    crypt = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA.new, salt, value)
    super "#{salt}::#{crypt}"
  end

  # Authenticate against the supplied password.
  def authenticated?(against)
    return false unless password
    salt, crypt = password.split('::')
    crypt == OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA.new, salt, against)
  end

  # Sets a new password for this person and returns the password in clear text.
  def new_password!
    self.password = Array.new(10) { (65 + rand(58)).chr }.join
  end

  # Sets a new access key for this person. Access key is read-only and this is the only way
  # to change it, for example, if the previous access key has been compromised. Returns the
  # new access key.
  def new_access_key!
    self.access_key = ActiveSupport::SecureRandom.hex(16)
  end

  before_save do |record| 
    record.new_access_key! unless record.access_key
  end


  # -- Guarded task update --

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
    update_task!(task, attributes)
  rescue ActiveRecord::RecordInvalid
    return false
  end

  # Similar to #update_task, but raises ActiveRecord::InvalidRecord in case of validation error.
  def update_task!(task, attributes)
    task.errors.clear

    new_owner = attributes[:owner] && Person.identify(attributes[:owner])
    if new_owner != task.owner
      if task.owner # owned, so delegating to someone else
        task.errors.add :owner, "Only owner or supervisor can change ownership" unless task.in_role?(:owner, self) || task.in_role?(:supervisor, self)
      else # not owned, so claiming task
        task.errors.add :owner, "#{new_owner.to_param} is not allowed to claim task" unless new_owner.can_claim?(task)
      end
    end
    raise ActiveRecord::RecordInvalid, task unless task.errors.empty?

    task.attributes = attributes

    # Check authorization to state changes.
    if task.status_changed?
      case task.status_was
      when 'suspended'
        task.errors.add :status, "Only supervisor is allowed to resume this task" unless task.cancelled? || task.in_role?(:supervisor, self)
      end

      case task.status
      when :suspended
        task.errors.add :status, "Only supervisor is allowed to suspend this task" unless task.in_role?(:supervisor, self)
      when :completed
        task.errors.add :status, "Only owner can complete task" unless task.owner == self
      when :cancelled
        task.errors.add :status, "Only supervisor allowed to cancel this task" unless task.in_role?(:supervisor, self)
      end
    end

    unless task.in_role?(:supervisor, self)
      # Supervisors can change anything, owners only data, status is looked at separately. 
      changed = task.changed - ['status']
      changed -= ['data'] if task.in_role?(:owner, self)
      unless changed.empty?
        task.errors.add_to_base "You are not allowed to change the attributes #{changed.to_sentence}"
      end
    end

    raise ActiveRecord::RecordInvalid, task unless task.errors.empty?
    task.save or raise ActiveRecord::RecordNotSaved
  end


  # -- Access control to task --

  # Returns true if this person can claim the task.
  def can_claim?(task)
    task.available? && can_own?(task, self)
  end

  def can_delegate?(task, person)
    (task.owner == self || task.in_role?(:supervisor, self)) && can_own?(task, person)
  end

  def can_own?(task, person)
    (task.in_role?(:potential_owner, person) || task.in_role?(:supervisor, person)) && !task.in_role?(:excluded_owner, person)
  end
  private :can_own?

  # Returns true if this person can suspend the task.
  def can_suspend?(task)
    task.available? && task.in_role?(:supervisor, self)
  end

  # Returns true if this person can resume the task.
  def can_resume?(task)
    task.suspended? && task.in_role?(:supervisor, self)
  end

  # Returns true if this person can cancel the task.
  def can_cancel?(task)
    !task.completed? && !task.cancelled? && task.in_role?(:supervisor, self)
  end

  # Returns true if this person can complete the task.
  def can_complete?(task)
    task.active? && task.in_role?(:owner, self)
  end

end
