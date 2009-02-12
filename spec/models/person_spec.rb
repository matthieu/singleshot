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


require File.dirname(__FILE__) + '/helpers'


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
describe Person do

  subject { Person.make }

  it { should have_attribute(:identity, :string, :null=>false) }
  it { should allow_mass_assigning_of(:identity) }
  it { should validate_uniquness_of(:identity) }
  it('should set identity from email if unspecified') { subject.valid? ; subject.identity.should == 'john.smith' }

  it { should have_attribute(:email, :string, :null=>false) }
  it { should allow_mass_assigning_of(:email) }
  it { should validate_presence_of(:email) }
  it { should validate_uniquness_of(:email) }

  it { should have_attribute(:fullname, :string, :null=>false) }
  it { should allow_mass_assigning_of(:fullname) }
  it('should set fullname from email if unspecified') { subject.valid? ; subject.fullname.should == 'John Smith' }

  it { should have_attribute(:timezone, :integer, :null=>true, :limit=>4) }
  it { should allow_mass_assigning_of(:timezone) }
  it { should_not validate_presence_of(:timezone) }

  it { should have_attribute(:locale, :string, :null=>true, :limit=>5) }
  it { should allow_mass_assigning_of(:locale) }
  it { should_not validate_presence_of(:locale) }

  def salt # return the password's salt
    subject.password.split('::').first
  end
  def crypt # return the password's crypt
    subject.password.split('::').last
  end
  def authenticate(password) # expecting authenticated?(password) to return true
    simple_matcher("authenticate '#{password}'") { |given| given.authenticated?(password) }
  end

  it { should have_attribute(:password, :string, :null=>true, :limit=>64) }
  it { should allow_mass_assigning_of(:password) }
  it { should_not validate_presence_of(:password) }
  it('should store salt as part of password')             { salt.should =~ /^[0-9a-f]{10}$/ }
  it('should store hexdigest as part of password')        { crypt.should look_like_hexdigest(40) }
  it('should use HMAC to crypt password')                 { crypt.should == OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA.new, salt, "secret") }
  it('should be <= 64 digits in crypt form')              { subject.password.size.should <= 64 }
  it('should not have same crypt for two people')         { Person.named('alice', 'bob', 'mary').map(&:password).uniq.size.should be(3) }
  it('should authenticate the right password')            { should authenticate('secret') }
  it('should not authenticate the wrong password')        { should_not authenticate('wrong') }
  it('should not authenticate without a password')        { subject[:password] = nil ; should_not authenticate('') }

  it { should have_attribute(:access_key, :string, :null=>false, :limit=>32) }
  it { should_not allow_mass_assigning_of(:access_key) }
  it('should create secure random access key')            { subject.save ; subject.access_key.should look_like_hexdigest(32) }
  it('should give each person unique access key')         { Person.named('alice', 'bob', 'mary').map(&:access_key).uniq.size.should be(3) }

  it { should have_created_at_timestamp }
  it { should have_updated_at_timestamp }


  describe '.authenticate' do
    subject { Person.make }

    # Expecting Person.authenticate(identity, password) to return subject
    def authenticate(identity, password)
      simple_matcher("authenticate '#{identity}:#{password}'") { |given| Person.authenticate(identity, password) == subject }
    end

    it('should return person if identity/password match')   { should authenticate('john.smith', 'secret') }
    it('should not return person unless password matches')  { should_not authenticate('john.smith', 'wrong') }
    it('should not return person unless identity matches')  { should_not authenticate('john.wrong', 'secret') }
  end


  describe '.identify' do
    subject { Person.make }

    # Expecting Person.identify(identity) to return subject
    def identify(identity)
      simple_matcher("identify '#{identity}'") { |given, matcher| wrap_expectation(matcher) { Person.identify(identity) == subject } }
    end
   
    it('should return same Person as argument')   { should identify(subject) }
    it('should return person with same identity') { should identify(subject.identity) }
    it('should fail if no person identified')     { should_not identify('missing') }
  end


  describe '#update_task' do
    subject { Task.make }

    it('should return true if no errors')   { Person.supervisor.update_task(subject, {}).should be_true }
    it('should save updated if no errors')  { subject.should_receive(:save).and_return(true)
                                              Person.supervisor.update_task(subject, {}) }
    it('should return false if errors')     { Person.owner.update_task(subject, :status=>'suspended').should be_false } 
    it('should not save updates if errors') { subject.should_not_receive(:save)
                                              Person.owner.update_task(subject, :status=>'suspended') }
  end

  describe '#update_task!' do
    subject { Task.make }

    it('should return true if no errors')   { Person.supervisor.update_task!(subject, {}).should be_true }
    it('should save updated if no errors')  { subject.should_receive(:save).and_return(true)
                                              Person.supervisor.update_task!(subject, {}) }
    it('should raise exception if errors')  { lambda { Person.owner.update_task!(subject, :status=>'suspended').should be_false }.should raise_error }
    it('should not save updates if errors') { subject.should_not_receive(:save)
                                              Person.owner.update_task!(subject, :status=>'suspended') rescue nil }
  end

end
