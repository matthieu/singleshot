# == Schema Information
# Schema version: 20080506015153
#
# Table name: activities
#
#  id         :integer         not null, primary key
#  person_id  :integer
#  task_id    :integer
#  action     :string(255)     not null
#  created_at :datetime        not null
#

class Activity < ActiveRecord::Base

  belongs_to :person
  belongs_to :task
  validates_presence_of :task_id

  attr_readonly :person, :task, :action

  named_scope :for_stakeholder, lambda { |person|
    { :joins=>'JOIN stakeholders AS involved ON involved.task_id=tasks.id',
      :conditions=>["involved.person_id=? AND involved.role != 'excluded'", person.id],
      :include=>[:task, :person], :order=>'activities.created_at DESC' } }
  named_scope :for_dates, lambda { |dates|
    { :conditions=>{ :created_at=>dates } } }

end
