# == Schema Information
# Schema version: 20080621023051
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
  validates_presence_of :name

  def readonly?
    !new_record?
  end

  named_scope :for_stakeholder, lambda { |person|
    { :joins=>'JOIN stakeholders AS involved ON involved.task_id=tasks.id',
      :conditions=>["involved.person_id=? AND involved.role != 'excluded'", person.id],
      :include=>[:task, :person], :order=>'activities.created_at DESC' } }
  named_scope :for_dates, lambda { |range|
    case range
    when Date
      range = range.to_time..Time.current.end_of_day
    when Range
      range = range.min.to_time.beginning_of_day..range.max.to_time.end_of_day
    end
    { :conditions=>{ :created_at=>range } } }

end
