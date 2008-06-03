# == Schema Information
# Schema version: 20080506015153
#
# Table name: activities
#
#  id         :integer         not null, primary key
#  person_id  :integer
#  task_id    :integer         not null
#  action     :string(255)     not null
#  created_at :datetime        not null
#

class Activity < ActiveRecord::Base

  belongs_to :person
  belongs_to :task
  validates_presence_of :task
  validates_presence_of :action

  def readonly?
    !new_record?
  end

  named_scope :for_stakeholder, lambda { |person|
    { :joins=>'JOIN stakeholders AS involved ON involved.task_id=tasks.id',
      :conditions=>["involved.person_id=? AND involved.role != 'excluded'", person.id],
      :include=>[:task, :person], :order=>'activities.created_at DESC' } }
  named_scope :for_dates, lambda { |dates|
    range = dates.min.to_time.beginning_of_day..dates.max.to_time.end_of_day
    { :conditions=>{ :created_at=>range } } }

end
