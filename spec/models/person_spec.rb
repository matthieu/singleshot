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

  it { should have_attribute(:identity) }
  it { should have_db_column(:identity, :type=>:string) }
  it { should allow_mass_assignment_of(:identity, :allow_nil=>true) }
  it { should validate_uniqueness_of(:identity) }
  it ('should set identity from email if unspecified') { subject.valid? ; subject.identity.should == 'john.smith' }

  it { should have_attribute(:email) }
  it { should have_db_column(:email, :type=>:string) }
  it { should allow_mass_assignment_of(:email) }
  it { should validate_presence_of(:email, :message=>"I need a valid e-mail address.") }
  it { should validate_uniqueness_of(:email) }
  it { should validate_email(:email) }

  it { should have_attribute(:fullname) }
  it { should have_db_column(:fullname, :type=>:string) }
  it { should allow_mass_assignment_of(:fullname) }
  it ('should set fullname from email if unspecified') { subject.valid? ; subject.fullname.should == 'John Smith' }

  it { should have_attribute(:timezone) }
  it { should have_db_column(:timezone, :type=>:integer) }
  it { should allow_mass_assignment_of(:timezone) }
  it { should_not validate_presence_of(:timezone) }

  it { should have_attribute(:locale) }
  it { should have_db_column(:locale, :type=>:string) }
  it { should allow_mass_assignment_of(:locale) }
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

  it { should have_attribute(:password) }
  it { should have_db_column(:password, :type=>:string) }
  it { should allow_mass_assignment_of(:password) }
  it { should_not validate_presence_of(:password) }
  it('should store salt as part of password')             { salt.should =~ /^[0-9a-f]{10}$/ }
  it('should store hexdigest as part of password')        { crypt.should =~ /^[0-9a-f]{40}$/ }
  it('should use HMAC to crypt password')                 { crypt.should == OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA.new, salt, "secret") }
  it('should be <= 64 digits in crypt form')              { subject.password.size.should <= 64 }
  it('should not have same crypt for two people')         { Person.named('alice', 'bob', 'mary').map(&:password).uniq.size.should be(3) }
  it('should authenticate the right password')            { should authenticate('secret') }
  it('should not authenticate the wrong password')        { should_not authenticate('wrong') }
  it('should not authenticate without a password')        { subject[:password] = nil ; should_not authenticate('') }

  it { should have_attribute(:access_key) }
  it { should have_db_column(:access_key, :type=>:string, :limit=>32) }
  it { should_not allow_mass_assignment_of(:access_key) }
  it('should create secure random access key')            { subject.save ; subject.access_key.should =~ /^[0-9a-f]{32}$/ }
  it('should give each person unique access key')         { Person.named('alice', 'bob', 'mary').map(&:access_key).uniq.size.should be(3) }

  it { should have_attribute(:created_at) }
  it { should have_db_column(:created_at, :type=>:datetime) }
  it { should have_attribute(:updated_at) }
  it { should have_db_column(:updated_at, :type=>:datetime) }

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

  describe '.tasks' do

    describe '.create' do
      before  { @bob = Person.named('bob') }
      subject { @bob.tasks.create(:title=>'foo') }

      it('should save task')                                { subject.should == Task.last }
      it('should return new task, modified_by person')      { subject.modified_by.should == @bob }
      it('should associate task with person as creator')    { subject.in_role('creator').should == [@bob] }
      it('should associate task with person as supervisor') { subject.in_role('supervisor').should == [@bob] }
    end

    describe '.create!' do
      before  { @bob = Person.named('bob') }

      it('should return task if new task created')        { @bob.tasks.create!(:title=>'foo').should be_kind_of(Task) }
      it('should raise error unless task created')        { lambda { @bob.tasks.create! }.should raise_error }
    end

    describe '.find' do
      before  do
        @bob = Person.named('bob')
        2.times do
          @bob.tasks.create! :title=>'foo'
        end
        Person.named('alice').tasks.create :title=>'bar'
      end

      it('should return the task, modified_by person')      { @bob.tasks.find(Task.first).modified_by.should == @bob }
      it('should return tasks, modified_by person')         { @bob.tasks.find(:all).map(&:modified_by).uniq.should == [@bob] }
      it('should not return tasks inaccessible to person')  { @bob.tasks.find(:all).size.should == 2 }
    end

  end

end
