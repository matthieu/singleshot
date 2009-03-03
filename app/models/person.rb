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


  # -- Tasks --

  has_many :activities, :dependent=>:delete_all
  has_many :stakeholders, :dependent=>:delete_all
  has_many :tasks, :through=>:stakeholders, :uniq=>true do

    # Create the task on behalf of its creator. For example:
    #   creator = Person.find(authenticated)
    #   creator.tasks.create(attributes)
    def create(attributes = {})
      Task.create attributes do |task|
        task.modified_by = proxy_owner
        task.stakeholders.build :role=>:creator, :person=>proxy_owner if task.in_role(:creator).empty?
        task.stakeholders.build :role=>:supervisor, :person=>proxy_owner if task.in_role(:supervisor).empty?
      end
    end

    # Similar to #create but throws RecordNotSaved if it fails to create a new record.
    def create!(attributes = {})
      task = create(attributes)
      raise ActiveRecord::RecordNotSaved if task.new_record?
      task
    end
    
    # Use this to find a task and update it on behalf of this person. For example:
    #   task = owner.tasks.find(task_id)
    #   task.update_attributes :status=>:completed
    def find(*args)
      super.tap do |found|
        Array(found).each do |task|
          task.modified_by = proxy_owner
        end
      end
    end

  end

  # -- Access control to task --

  # Returns true if this person can claim the task. Offered to potential owners and supervisors.
  def can_claim?(task)
    task.available? && task.can_own?(self)
  end

  # Returns true if this person can delegate the task. Offered to current owner and supervisor.
  def can_delegate?(task, person = nil)
    (task.owner == self || task.in_role?(:supervisor, self)) && (person.nil? || task.can_own?(person))
  end

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

  # Returns true if this person can complete the task. Must be owner of an active task.
  def can_complete?(task)
    task.active? && task.in_role?(:owner, self)
  end

  # Returns true if this person can change various task attributes.
  def can_change?(task)
    !task.completed? && !task.cancelled? && task.in_role?(:supervisor, self)
  end

end
