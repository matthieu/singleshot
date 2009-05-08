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
  it_should_behave_like 'Base'
  subject { Notification.make rescue p $! }

  should_be_kind_of Notification
  should_allow_mass_assignment_of :title, :description, :language, :priority
  should_allow_mass_assignment_of :creator, :recipients
  it('should be readonly') { lambda { subject.save! }.should raise_error(ActiveRecord::ReadOnlyRecord) }

  it('should require at least one recipient') { Notification.new.should have(1).error_on(:recipients) }


  describe 'received' do
    before do
      2.times { |i| Notification.make :id=>i + 1 }
      3.times { |i| Notification.make :id=>i + 3, :recipients=>[Person.me], :created_at=>Time.now - (i - 3).minutes }
    end
    subject { Person.me.notifications.received }

    it('should only include notifications sent to me') { subject.all? { |notif| notif.recipients.should include(Person.me) } }
    it('should return most recent notification first') { subject.should == Notification.find(5,4,3) }
  end

  # TODO: Send e-mail after creation
end
