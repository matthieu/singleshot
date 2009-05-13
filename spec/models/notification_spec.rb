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
  subject { Notification.make }

  should_have_column :subject, :body, :type=>:string
  should_have_column :language, :type=>:string, :limit=>5
  should_have_column :priority, :type=>:integer, :limit=>1
  should_belong_to :creator, :class_name=>'Person'
  should_have_many :copies, :dependent=>:delete_all, :uniq=>true
  should_have_many :recipients, :through=>:copies

  should_allow_mass_assignment_of :subject, :body, :language, :priority, :creator, :recipients
  should_validate_presence_of :subject
  should_not_validate_presence_of :body, :language, :creator, :recipients

  it('should be readonly') { lambda { subject.save! }.should raise_error(ActiveRecord::ReadOnlyRecord) }
  it('should create one copy for each recipient') { subject.copies.map(&:recipient).sort.should == [Person.observer, Person.owner] }


  # -- Notification received by person, read & unread --

  describe 'for person' do
    before do
      2.times { |i| Notification.make :id=>i + 1, :recipients=>[Person.observer] }
      3.times { |i| Notification.make :id=>i + 3, :created_at=>Time.now - (i - 3).minutes }
    end
    subject { Person.owner.notifications }

    it('should only include notifications sent to me') { subject.all? { |copy| copy.recipient.should == Person.owner } }
    it('should return most recent notification first') { subject.should == Notification::Copy.all(:conditions=>{ :recipient_id=>Person.owner, :notification_id=>[5,4,3]}) }
  end

  describe '.read' do
    before do
      3.times { |i| Notification.make :id=>i + 1, :created_at=>Time.now - (i -3).minutes }
      Notification.find(2).read! Person.observer
      Notification.find(3).read! Person.owner
    end
    subject { Person.observer.notifications.read }

    it('should only include read notifications')    { subject.all? { |copy| copy.should be_read } }
    it('should include all my notifications')       { subject.should == Notification::Copy.all(:conditions=>{ :recipient_id=>Person.observer, :notification_id=>[2] }) }
  end

  describe '.unread' do
    before do
      3.times { |i| Notification.make :id=>i + 1, :created_at=>Time.now - (i -3).minutes }
      Notification.find(2).read! Person.observer
      Notification.find(3).read! Person.owner
    end
    subject { Person.observer.notifications.unread }

    it('should only include unread notifications')  { subject.all? { |copy| copy.should_not be_read } }
    it('should include all my notifications')       { subject.should == Notification::Copy.all(:conditions=>{ :recipient_id=>Person.observer, :notification_id=>[3,1] }) }
  end


  # -- Notification copy --

  describe 'Copy' do
    subject { Notification.make.copies.last }
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


  # -- Notification e-mail --

  it('should send email to all recipients')             { subject ; ActionMailer::Base.deliveries.map(&:to).flatten.sort.should == subject.recipients.map(&:email).sort }
  it('should send individual email to each recipient')  { subject ; ActionMailer::Base.deliveries.all? { |d| d.to.size.should == 1 } }

end
