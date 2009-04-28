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


require File.dirname(__FILE__) + '/../helpers'

describe '/tasks/show' do
  before do
    @task = Task.make :title=>"Absence request", :description=>"Employee wants their leave of absence approved"
    template.stub!(:authenticated).and_return Person.observer
    template.stub!(:instance).and_return { Task.find(@task) }
  end
  subject { render '/tasks/show', :layout=>'single' }


  should_have_tag 'title', "Singleshot &mdash; Absence request"
  should_have_tag 'script[src^=/javascripts/jquery.js]'
  should_have_tag 'script[src^=/javascripts/singleshot.js]'
  should_have_tag 'link[href^=/stylesheets/common.css]'
  should_have_tag 'link[href^=/stylesheets/task.css]'

  should_have_tag 'div#header + div#details'
  should_have_tag '#header ol.sections li', 3
  should_have_tag '#header ol.sections li.logo + li.meta + li.actions'
  should_have_tag '#header ol.sections li.meta span.title', "Absence request"
  should_not_have_tag '#header ol.sections li.actions form'
  should_have_tag '#details div.description + hr + ul.meta + ol.activities'
  should_have_tag '#details div.description', "Employee wants their leave of absence approved"
  should_have_tag '#details ul.meta li.priority.priority-2', "Normal priority"
  should_not_have_tag '#details ul.meta li.due_on'
  should_have_tag '#details ol.activities li span.title + span.created'
  should_have_tag '#details ol.activities li span.title a.fn.url'
  should_have_tag '#details ol.activities li', /Creator created this task/
  

  describe 'to owner' do
    before do
      Person.owner.task(@task).update_attributes! :owner=>Person.owner
      template.stub!(:authenticated).and_return Person.owner
      render '/tasks/show', :layout=>'single'
    end

    should_have_tag '#details ol.activities li', /Owner is owner of this task/
    should_have_tag '#header ol.sections li.actions form input[value=Done]'
    should_not_have_tag '#header ol.sections li.actions form input[value=Claim]'
  end

  describe 'to potential owner' do
    before do
      template.stub!(:authenticated).and_return Person.owner
      render '/tasks/show', :layout=>'single'
    end

    should_have_tag '#header ol.sections li.actions form input[value=Claim]'
    should_not_have_tag '#header ol.sections li.actions form input[value=Done]'
    should_not_have_tag '#header ol.sections li.actions form input[value=Cancel]'
  end

  describe 'to supervisor' do
    before do
      template.stub!(:authenticated).and_return Person.supervisor
      render '/tasks/show', :layout=>'single'
    end

    should_have_tag '#header ol.sections li.actions form input[value=Cancel]'
  end
  
  
  describe 'with low priority task' do
    before do
      Person.supervisor.task(@task).update_attributes! :priority=>3
      render '/tasks/show', :layout=>'single'
    end
    
    should_have_tag '#details ul.meta li.priority', "Low priority"
  end

  describe 'with high priority task' do
    before do
      Person.supervisor.task(@task).update_attributes! :priority=>1
      render '/tasks/show', :layout=>'single'
    end
    
    should_have_tag '#details ul.meta li.priority', "High priority"
  end

  describe 'with due on date' do
    before do
      Person.supervisor.task(@task).update_attributes! :due_on=>Date.new(2009,4,19)
      render '/tasks/show', :layout=>'single'
    end
    
    should_have_tag '#details ul.meta li.due_on', "Due on April 19, 2009"
  end
  
  
  describe 'activities' do
    before do
      Person.owner.task(@task).update_attributes! :owner=>Person.owner
      Person.supervisor.task(@task).update_attributes! :priority=>1
      render '/tasks/show', :layout=>'single'
    end
    
    should_have_tag '#details ol.activities', /Creator created this task/
    should_have_tag '#details ol.activities', /Owner is owner of this task/
    should_have_tag '#details ol.activities', /Supervisor modified this task/
  end
  
  
  describe 'with no form' do
    before do
      Person.owner.task(@task).update_attributes! :owner=>Person.owner, :form=>{}
      template.stub!(:authenticated).and_return Person.owner
      render '/tasks/show', :layout=>'single'
    end
    
    should_not_have_tag 'iframe'
    should_have_tag '#header ol.sections li.actions form input[value=Done]'
  end
  
  describe 'with form' do
    before do
      Person.owner.task(@task).update_attributes! :owner=>Person.owner, :form=>{ :html=>'<input>' }
      assigns[:iframe_url] = 'http://localhost'
      render '/tasks/show', :layout=>'single'
    end
    
    should_have_tag 'iframe#frame[noresize][src=http://localhost]'
    should_not_have_tag '#header ol.sections li.actions form input[value=Done]'
  end
end
