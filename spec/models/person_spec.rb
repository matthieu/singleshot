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


describe Person do

  def look_like_sha1
    simple_matcher('look like a SHA1') { |given| given =~ /^[0-9a-f]{40}$/ }
  end

  def allow_mass_assigning_of(attr, new_value = 'new value')
    simple_matcher "allow mass assigning of #{attr}" do |given|
      given.attributes = { attr=>new_value }
      given.changed.include?(attr.to_s)
    end
  end


  describe :password do
    subject { Person.new :email=>'john.smith@example.com', :password=>'secret' }
    def salt ; subject.password.split(':').first ; end
    def crypt ; subject.password.split(':').last ; end

    it('should contain salt prefix') { salt.should =~ /^[0-9a-f]{10}$/ }
    it('should contain SHA1 crypt')  { crypt.should look_like_sha1 }
    it('should calculate crypt using salt') { crypt.should == SHA1.hexdigest("#{salt}:secret") }
    it 'should not reuse salt' do
      passwords = (1..10).map { Person.new(:password=>'secret').password }
      passwords.uniq == passwords
    end

    it { should allow_mass_assigning_of(:password) }
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
end


=begin
describe Person do
  
  describe 'activities' do
    before do
      Task.create! defaults(:creator=>person('creator'), :owner=>person(:owner))
      Task.create! defaults(:owner=>person(:owner))
    end
  
    it 'should return all activities associated with that person' do
      person(:creator).activities.map { |a| [a.name, a.task, a.person] }.
        should include(['created', Task.first, person(:creator)])
      person(:owner).activities.map { |a| [a.name, a.task, a.person] }.
        should include(['owner', Task.first, person(:owner)], ['owner', Task.last, person(:owner)])
    end
    
    it 'should return only activities associated with that person' do
      person(:creator).activities.map(&:person).uniq.should == [person(:creator)]
      person(:owner).activities.map(&:person).uniq.should == [person(:owner)]
    end
    
    it 'should allow eager loading with dependents' do
      person(:owner).activities.with_dependents.proxy_options[:include].should include(:task, :person)
    end
    
  end
  
end
=end
