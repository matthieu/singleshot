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
    it('should return most HTML verbatim')    { rich_text("<b>TPS</b> report<br>").should =~ /<b>TPS<\/b> report<br>/ }
    it('should sanitize HTML')                { rich_text("<script>boo!</script><a href=\"javascript:void\">link</a>").should == "<p><a>link</a></p>" }
    it('should format paragraphs')            { rich_text("yes\n\nno").should =~ /<p>yes<\/p>\s*<p>no<\/p>/ }
    it('should transform links')              { rich_text("http://cool").should =~ /<a href="http:\/\/cool">http:\/\/cool<\/a>/ }
  end

end
