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


# == Schema Information
# Schema version: 20090421005807
#
# Table name: tasks
#
#  id           :integer(4)      not null, primary key
#  status       :string(255)     not null
#  title        :string(255)     not null
#  description  :string(255)
#  language     :string(5)
#  priority     :integer(1)      not null
#  due_on       :date
#  start_on     :date
#  cancellation :string(255)
#  data         :text            default(""), not null
#  hooks        :string(255)
#  access_key   :string(32)      not null
#  version      :integer(4)      not null
#  created_at   :datetime
#  updated_at   :datetime
#  type         :string(255)     not null
#
describe Template do
  it_should_behave_like 'Base'
  subject { Template.make }

  should_be_kind_of Template
  should_allow_mass_assignment_of :title, :description, :language, :status, :priority, :form, :data, :webhooks
  should_allow_mass_assignment_of :creator, :supervisors, :potential_owners, :excluded_owners, :observers
  should_not_allow_mass_assignment_of :due_on, :start_on, :stakeholders, :owner, :past_owners
  should_have_readonly_attribute :creator

  should_validate_inclusion_of :status, :in=>['enabled', 'disabled']
  it('should default status to enabled') { subject.status.should == 'enabled' }

  should_have_named_scope :listed_for, :with=>'edward', :joins=>"JOIN stakeholders AS involved ON involved.task_id=tasks.id",
    :conditions=>["involved.person_id = ? AND involved.role = 'potential_owner' AND status = 'enabled'", 'edward']
  should_have_named_scope :accessible_to, :with=>'edward', :joins=>"JOIN stakeholders AS involved ON involved.task_id=tasks.id",
    :conditions=>["involved.person_id = ? AND involved.role != 'excluded_owner'", 'edward']
  should_have_default_scope :order=>'title ASC'

  describe 'to_task' do
    before do
      @template = Template.make
      Person.owner.template(@template).to_task.save!
      @attributes = 'title', 'description', 'language', 'priority', 'form', 'data', 'webhook'
    end
    subject { Task.last }
    
    should_be_active
    it('should be created by new owner') { subject.creator.should == Person.owner }
    it('should be owned by new owner')   { subject.owner.should == Person.owner }
    it('should have same potential owners as template') { subject.potential_owners.should == @template.potential_owners }
    it('should have same excluded owners as template')  { subject.excluded_owners.should == @template.excluded_owners }
    it('should have same supervisors as template')      { subject.supervisors.should == @template.supervisors }
    it('should have same core attributes as template')  { subject.attributes.should include(@template.attributes.slice(@attributes)) }
    it('should clone form')                             { subject.form.should_not be(@template.form) }
  end

  describe 'newly created' do
    subject { Person.creator.templates.create!(:title=>'foo') }

    should_be_enabled
    it('should have creator')                     { subject.creator.should == Person.creator }
    it('should have creator as supervisor')       { subject.supervisors.should == [Person.creator] }
    should_log_activity Person.creator, 'template.created'
  end

  describe 'disabled' do
    before do
      Template.make
      Person.supervisor.template(Template.last).update_attributes! :status=>'disabled'
    end
    subject { Template.last }

    should_be_disabled
    should_log_activity Person.supervisor, 'template.disabled'
  end

  describe 'ensabled' do
    before do
      Template.make :status=>'disabled'
      Person.supervisor.template(Template.last).update_attributes! :status=>'enabled'
    end
    subject { Template.last }

    should_be_enabled
    should_log_activity Person.supervisor, 'template.enabled'
  end

  describe 'can_update?' do
    it('should allow supervisor to update template')          { subject.can_update?(Person.supervisor).should be_true }
    it('should not allow creator to update template')         { subject.can_update?(Person.creator).should be_false }
    it('should not allow potential owner to update template') { subject.can_update?(Person.potential).should be_false }
  end

  describe 'can_destroy?' do
    it('should allow supervisor to destroy template')          { subject.can_update?(Person.supervisor).should be_true }
    it('should not allow creator to destroy template')         { subject.can_update?(Person.creator).should be_false }
    it('should not allow potential owner to destroy template') { subject.can_update?(Person.potential).should be_false }
  end
end
