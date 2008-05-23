# == Schema Information
# Schema version: 20080506015153
#
# Table name: activities
#
#  id         :integer         not null, primary key
#  person_id  :integer         not null
#  task_id    :integer         not null
#  action     :string(255)     not null
#  created_at :datetime        not null
#

class Activity < ActiveRecord::Base

  belongs_to :person
  belongs_to :task

  attr_readonly :person, :task, :action

  module GroupingMethods
    def group_by_day
      self.inject([]) do |days, activity|
        created = activity.created_at.to_date
        day = days.last if days.last && days.last.first == created
        days << (day = [created, []]) unless day
        day.last << activity
        days
      end
    end
  end

  named_scope :for_stakeholder,
    lambda { |person| { :joins=>'JOIN stakeholders AS involved ON involved.task_id=tasks.id',
      :conditions=>["involved.person_id=? AND involved.role != 'excluded'", person.id],
      :include=>[:task, :person], :order=>'activities.created_at DESC', :extend=>GroupingMethods } }
  named_scope :for_dates,
    lambda { |dates| { :conditions=>{ :created_at=>dates } } }

  class << self

    def log(task, modified_by)
      activities = Hash.new
      class << activities ; self ;end.send :define_method, :add do |*args|
        person = Person === args.first ? args.shift : modified_by
        self[person] = Array(self[person]).push(*args) if person
      end
      yield activities
      activities.each do |person, actions|
        task.activities.build :person=>person, :action=>actions.to_sentence
      end
    end

  end

end
