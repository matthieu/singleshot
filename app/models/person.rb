# == Schema Information
# Schema version: 20080506015153
#
# Table name: people
#
#  id         :integer         not null, primary key
#  identity   :string(255)     not null
#  fullname   :string(255)     not null
#  email      :string(255)     not null
#  language   :string(5)
#  timezone   :integer(4)
#  password   :string(64)
#  access_key :string(32)      not null
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
      when Array then identity.flatten.map { |id| identify(id) }.uniq 
      when Person then identity
      else Person.find_by_identity(identity)
      end
    end

    # Used for identity/password authentication.  Return the person if authenticated.
    def authenticate(login, password)
      person = Person.find_by_identity(login)
      person if person && person.password?(password)
    end

  end

  def initialize(*args)
    super
    self.access_key!
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

  before_validation :fix_attributes
  def fix_attributes
    self.email = email.to_s.strip.downcase
    self.identity = email.to_s.strip[/([^\s@]*)/, 1].downcase if identity.blank?
    self.identity = identity.strip.gsub(/\s+/, '_').downcase
    self.fullname = email.to_s.strip[/([^\s@]*)/, 1].split(/[_.]+/).map(&:capitalize).join(' ') if fullname.blank?
    self.fullname = fullname.strip.gsub(/\s+/, ' ')
  end
  private :fix_attributes

  # TODO:  Some way to check minimum size of passwords.

  def password=(password)
    seed = SHA1.hexdigest(OpenSSL::Random.random_bytes(128))[0,10]
    crypted = SHA1.hexdigest("#{seed}:#{password}")
    self[:password] = "#{seed}:#{crypted}"
  end

  def password?(password)
    return false unless self[:password]
    seed, crypted = self[:password].split(':')
    crypted == SHA1.hexdigest("#{seed}:#{password}")
  end

  def reset_password!
    password = Array.new(10) { (65 + rand(58)).chr }.join
    self.password = password  
    save!
    password
  end

  attr_protected :access_key

  def access_key!
    self.access_key = SHA1.hexdigest(OpenSSL::Random.random_bytes(128))
    save! unless new_record?
  end

  def url
    read_attribute(:identity)
  end

  has_many :activities, :dependent=>:delete_all
  has_many :stakeholders, :dependent=>:delete_all

end
