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
    assigns[:atom_feed_url].should == formatted_activity_url(:format=>:atom, :access_key=>authenticated.access_key)
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
