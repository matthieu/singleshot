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


describe Person do

  it { should have_created_at_timestamp }
  it { should have_updated_at_timestamp }


  describe :identity do
    subject { Person.new :email=>'john.smith@example.com' }

    it { should allow_mass_assigning_of(:identity) }
    it('should set from email if unspecified') { subject.valid? ; subject.identity.should == 'john.smith' }
    it { should validate_uniquness_of!(:identity) }
  end


  describe :fullname do
    subject { Person.new :email=>'john.smith@example.com' }

    it { should allow_mass_assigning_of(:fullname) }
    it('should set from email if unspecified') { subject.valid? ; subject.fullname.should == 'John Smith' }
  end


  describe :email do
    subject { Person.new :email=>'john.smith@example.com' }

    it { should allow_mass_assigning_of(:email) }
    it { should validate_presence_of(:email) }
    it { should validate_uniquness_of!(:email) }
  end


  describe :timezone do
    subject { Person.new }

    it { should allow_mass_assigning_of(:timezone) }
  end


  describe :password do
    subject { Person.new :email=>'john.smith@example.com', :password=>'secret' }
    def salt ; subject.password.split(':').first ; end
    def crypt ; subject.password.split(':').last ; end

    it { should allow_mass_assigning_of(:password) }
    it('should contain salt prefix') { salt.should =~ /^[0-9a-f]{10}$/ }
    it('should contain SHA1 crypt')  { crypt.should look_like_sha1 }
    it('should calculate crypt using salt') { crypt.should == SHA1.hexdigest("#{salt}:secret") }
    it 'should not reuse salt' do
      passwords = (1..10).map { Person.new(:password=>'secret').password }
      passwords.uniq == passwords
    end
    it('should authenticate if using the right password') { subject.authenticated?('secret').should be_true }
    it('should not authenticate if using the wrong password') { subject.authenticated?('wrong').should be_false }
    it('should not authenticate if missing') { Person.new.authenticated?('').should be_false }
  end

  describe '#authenticate' do
    subject { Person.new :email=>'john.smith@example.com', :password=>'secret' }
    before  { subject.save! }

    it('should authenticate person if identity & password match') { Person.authenticate('john.smith', 'secret').should == subject }
    it('should not authenticate person if wrong password') { Person.authenticate('john.smith', 'wrong').should be_nil }
    it('should not authenticate person if no such identity') { Person.authenticate('john.wrong', 'secret').should be_nil }
  end


  describe :access_key do
    subject { Person.create! :email=>'john.smith@example.com' }

    it { subject.access_key.should look_like_sha1 }

    it 'should be different for each person' do
      subject.access_key.should_not == Person.create!(:email=>'maple.syrup@example.com').access_key
    end

    it { should_not allow_mass_assigning_of(:access_key) }

    it 'should change by calling new_access_key!' do
      lambda { subject.new_access_key! }.should change { subject.access_key }
    end

    it 'should allow lookup' do
      subject.save
      should == Person.find_by_access_key(subject.access_key)
    end

    after { Person.delete_all }
  end


  describe '#identify' do
    subject { Person.create! :email=>'john.smith@example.com' }
   
    it('should return same Person as argument') { Person.identify(subject).should == subject }
    it('should return person with same identity') { Person.identify(subject.identity).should == subject }
    it('should fail if no person identified') { lambda { Person.identify('missing') }.should raise_error(ActiveRecord::RecordNotFound) }
  end

end
