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


require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ApplicationHelper do
  include ApplicationHelper

  describe 'link_to_person' do
    subject { link_to_person mock_model(Person, :url=>'http://test.host/john', :fullname=>'John Smith') }
    should_have_tag 'a.url[href=http://test.host/john]'
    should_have_tag 'a.fn', 'John Smith'
    should_have_tag 'a[title=John Smith\'s profile]'
  end

  describe 'rich_text' do
    before { self.class.extend ActionView::Helpers::SanitizeHelper::ClassMethods }
    it('should return simple text verbatim')  { rich_text("TPS report").should =~ /TPS report/ }
    it('should escape HTML')                  { rich_text("<b>TPS</b> report<br>").should =~ /&lt;b&gt;TPS&lt;\/b&gt; report&lt;br&gt;/ }
    it('should format paragraphs')            { rich_text("yes\n\nno").should =~ /<p>yes<\/p>\s*<p>no<\/p>/ }
    it('should transform links')              { rich_text("http://cool").should =~ /<a href="http:\/\/cool">http:\/\/cool<\/a>/ }
  end

  describe 'inbox_count' do
    subject { inbox_count }

    describe '(unauthenticated)' do
      it('should return empty string if not authenticated') { subject.should == '' }
    end
    describe '(authenticated)' do
      before { stub!(:authenticated).and_return { Person.owner } }
      before { Notification.make :recipients=>[Person.other] }
      before { Notification.make }
      it('should return count of unread notifications') { should have_tag('span.count', '1') }
      it('should return empty string if no unread notifiactions') { Notification::Copy.update_all :marked_read=>true ; subject.should == '' }
    end
  end

end
