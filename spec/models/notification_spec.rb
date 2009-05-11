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
require File.dirname(__FILE__) + '/base_spec'

describe Notification do
  #it_should_behave_like 'Base'
  subject { notification }

  should_be_kind_of Notification
  should_allow_mass_assignment_of :title, :description, :language, :priority
  should_allow_mass_assignment_of :creator, :recipients
  it('should be readonly') { lambda { subject.save! }.should raise_error(ActiveRecord::ReadOnlyRecord) }

  should_have_many :copies, :dependent=>:delete_all, :uniq=>true
  should_have_many :recipients, :through=>:copies
  should_allow_mass_assignment_of :recipients
  it('should create one copy for each recipient') { subject.copies.map(&:recipient).sort.should == [Person.owner, Person.potential] }


  describe '.read!' do
    before { subject.read!(Person.owner) }
    it('should mark notification as read')      { subject.copy(Person.owner).should be_read }
    it('should not modify other notifications') { subject.copy(Person.potential).should_not be_read } 
  end

  describe '.read?' do
    before { subject.copy(Person.owner).read! }
    it('should return true if notification read')      { subject.read?(Person.owner).should be_true }
    it('should return false if notification not read') { subject.read?(Person.potential).should be_false }
  end

  describe 'for person' do
    before do
      2.times { |i| notification :id=>i + 1 }
      3.times { |i| notification :id=>i + 3, :recipients=>[Person.me], :created_at=>Time.now - (i - 3).minutes }
    end
    subject { Person.me.notifications }

    it('should only include notifications sent to me') { subject.all? { |notif| notif.recipients.should include(Person.me) } }
    it('should return most recent notification first') { subject.should == Notification.find(5,4,3) }
  end

  describe '.read' do
    before do
      3.times { |i| notification :id=>i + 1, :recipients=>[Person.me, Person.other], :created_at=>Time.now - (i -3).minutes }
      Notification.find(2).read! Person.me
      Notification.find(3).read! Person.other
    end
    subject { Person.me.notifications.read }

    it('should only include read notifications')    { subject.all? { |notif| notif.read?(Person.me).should be_true } }
    it('should include all my notifications')       { subject.should == [Notification.find(2)] }
  end

  describe '.unread' do
    before do
      3.times { |i| notification :id=>i + 1, :recipients=>[Person.me, Person.other], :created_at=>Time.now - (i -3).minutes }
      Notification.find(2).read! Person.me
      Notification.find(3).read! Person.other
    end
    subject { Person.me.notifications.unread }

    it('should only include unread notifications')  { subject.all? { |notif| notif.read?(Person.me).should be_false } }
    it('should include all my notifications')       { subject.should == Notification.find(3,1) }
  end


  describe 'Copy' do
    subject { notification.copies.last }
    should_belong_to :notification
    should_belong_to :recipient
    should_have_readonly_attributes :notification, :recipient
    should_have_column :read, :type=>:boolean
    should_have_index [:notification_id, :recipient_id], :unique=>true
    should_have_index [:recipient_id, :read]

    describe '.read!' do
      it('should make copy as read') { lambda { subject.read! }.should change(subject, :read?).to(true) }
    end
  end

  # TODO: Send e-mail after creation
end
