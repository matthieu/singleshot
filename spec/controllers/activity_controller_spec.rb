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

=begin
describe ActivityController, 'index' do

  it 'should map to /activity' do
    route_for(:controller=>'activity', :action=>'index').should eql('/activity')
  end

  it 'should require authentication' do
    get 'index'
    response.should redirect_to(session_url)
  end
  
  it "should have 'Activities' in the title" do
    authenticate ; get 'index'
    assigns[:title].should == 'Activities'
  end
  
  it "should expand on the title in the subtitle" do
    authenticate ; get 'index'
    assigns[:subtitle].should == "Activity from all tasks you own or observe"
  end
  
  it 'should return activities for stakeholder with dependents and pagination' do
    paginated = (with_dependents = (for_stakeholder = Activity.for_stakeholder(person))).paginate(:page=>nil)
    Activity.should_receive(:for_stakeholder).with(person).and_return(for_stakeholder)
    for_stakeholder.should_receive(:with_dependents).and_return(with_dependents)
    with_dependents.should_receive(:paginate).and_return(paginated)
    authenticate ; get 'index'
    assigns[:activities].should == paginated
  end
  
  it "should paginate using query parameter 'page' and 50 items per page" do
    paginated = (with_dependents = (for_stakeholder = Activity.for_stakeholder(person))).paginate(:page=>nil)
    Activity.should_receive(:for_stakeholder).with(person).and_return(for_stakeholder)
    for_stakeholder.should_receive(:with_dependents).and_return(with_dependents)
    with_dependents.should_receive(:paginate).with(:page=>'5', :per_page=>50).and_return(paginated)
    authenticate ; get 'index', :page=>'5'
  end
  
  it 'should provide link to next result page (HTML only)' do
    paginated = mock('activities')
    Activity.stub!(:for_stakeholder).and_return(paginated)
    paginated.stub!(:method_missing).and_return(paginated)
    paginated.stub!(:next_page).and_return(2)
    authenticate ; get 'index', :page=>'1'
    assigns[:next].should == activity_url(:page=>'2')
  end

  it 'should provide link to previous result page (HTML only)' do
    paginated = mock('activities')
    Activity.stub!(:for_stakeholder).and_return(paginated)
    paginated.stub!(:method_missing).and_return(paginated)
    paginated.stub!(:previous_page).and_return(1)
    authenticate ; get 'index', :page=>'2'
    assigns[:previous].should == activity_url(:page=>'1')
  end

  it 'should provide link to Atom feed (HTML only)' do
    authenticate ; get 'index', :page=>'2'
    assigns[:atom_feed_url].should == activity_url(:format=>:atom, :access_key=>authenticated.access_key)
  end
  
  it 'should include graph with all activities in the past month (HTML only)' do
    for_stakeholder = Activity.for_stakeholder(person)
    Activity.should_receive(:for_stakeholder).and_return(for_stakeholder)
    graph = for_stakeholder.for_dates(Date.current - 1.month)
    for_stakeholder.should_receive(:for_dates).and_return(graph)
    authenticate ; get 'index'
    assigns[:graph].should == graph
  end

  it 'should set root_url to /activities (Atom onlu)' do
    authenticate ; get 'index', :format=>'atom'
    assigns[:root_url].should == activity_url
  end
end
=end
