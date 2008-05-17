class Activity < ActiveRecord::Base

  class << self

    def from_changes_to(task)
      returning [] do |activities|
        if task.changes['state']
          from, to = *task.changes['state']
          activities << new(:action=>'created', :person=>task.creator) if task.creator && from.nil? || from == 'reserved'
          activities << new(:action=>'resumed') if from == 'suspended'
          case to
          when 'ready'
          when 'active'
            activities << new(:action=>'own', :person=>task.owner)
          when 'suspended'
            activities << new(:action=>'suspended')
          when 'completed'
            activities << new(:action=>'completed', :person=>task.owner)
          when 'cancelled'
            activities << new(:action=>'cancelled')
          end
        else
          activities << new(:action=>'modified')
        end
      end
    end

  end

  belongs_to :person
  belongs_to :task

  attr_readonly :person, :task, :action

  module GroupByDay
    def group_by_day
      self.inject([]) { |days, activity|
        created = activity.created_at.to_date
        day = days.last if days.last && days.last.first == created
        days << (day = [created, []]) unless day
        day.last << activity
        days
      }
    end
  end

  named_scope :for_stakeholder,
    lambda { |person| { :joins=>'JOIN stakeholders AS involved ON involved.task_id=tasks.id',
      :conditions=>["involved.person_id=? AND involved.role != 'excluded'", person.id],
      :include=>[:task, :person], :order=>'activities.created_at DESC', :extend=>GroupByDay } }
  named_scope :for_dates,
    lambda { |dates| { :conditions=>{ :created_at=>dates } } }

end
