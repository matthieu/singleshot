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


share_examples_for Base do

  # -- Descriptive --

  should_have_attribute :title
  should_have_attribute :description
  should_have_attribute :language
  should_have_column :title, :description, :type=>:string
  should_have_column :language, :type=>:string, :limit=>5
  should_allow_mass_assignment_of :title, :description, :language
  should_not_validate_uniqueness_of :title
  should_validate_presence_of :title
  should_not_validate_presence_of :description, :language


  # -- Priority --

  should_have_attribute :priority
  should_have_column :priority, :type=>:integer, :limit=>1
  it('should default to priority 2') { subject.priority.should == 2 }
  should_validate_inclusion_of :priority, :in=>1..3


  # -- Status --

  should_have_attribute :status
  should_have_column :status, :type=>:string
  should_validate_presence_of :status
  should_allow_mass_assignment_of :status


  # -- Presentation --

  should_have_one :form, :dependent=>:delete


  # -- Data --

  should_have_attribute :data
  should_have_column :data, :type=>:text
  should_allow_mass_assignment_of :data
  it('should have empty hash as default data')  { subject.data.should == {} }
  it('should allowing assigning nil to data')   { subject.data = nil ; should have(:no).error_on(:data) }
  it('should validate data is a hash')          { subject.data = 'string' ; should have(1).error_on(:data) }


  # -- Access control --

  should_not_have_attribute :modified_by
  it('should have accessor modified_by') { subject.methods.should include('modified_by', 'modified_by=') }


  # -- Activity --
  
  should_have_many :activities, :include=>[:task, :person], :dependent=>:delete_all, :order=>'activities.created_at DESC'
  should_not_allow_mass_assignment_of :activities


  # Expecting a new activity to show up after yielding to block, matching record, person and name.
  # For example:
  #   it { should log_activity(Person.owner, 'completed') { Person.owner.tasks(id).update_attributes :status=>'completed' } }
  def log_activity(person, name)
    simple_matcher "log activity '#{person.to_param} #{name}'" do |given, matcher|
      if block_given?
        Activity.delete_all
        yield
      end
      activities = Activity.all
      matcher.failure_message = "expecting activity \"#{person.to_param} #{name} #{given.title}\" but got #{activities.empty? ? 'nothing' : activities.map(&:name).to_sentence.inspect} instead"
      activities.any? { |activity| activity.task == given && activity.person == person && activity.name == name }
    end
  end
end
