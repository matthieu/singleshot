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


# Activity stream records who did what to which task. Activities are logged
# when updating at task.
#
# == Schema Information
# Schema version: 20090402190432
#
# Table name: activities
#
#  id         :integer(4)      not null, primary key
#  person_id  :integer(4)      not null
#  task_id    :integer(4)      not null
#  name       :string(255)     not null
#  created_at :datetime        not null
#
class Activity < ActiveRecord::Base

  # Activity associated with a task.
  belongs_to :task
  validates_presence_of :task

  # Activity associated with a person.
  belongs_to :person
  validates_presence_of :person
  
  validates_presence_of :name

  attr_readable :name, :person, :created_at

  def readonly? #:nodoc:
    !new_record?
  end

  # Date activity was created at.
  def date
    @date ||= created_at.to_date
  end

  # Returns activities by recently added order.
  default_scope :order=>'activities.created_at desc'

  # Return activities created since a given date.
  named_scope :since, lambda { |date| { :conditions=>['activities.created_at >= ?', date] } } do
    # Returns datapoints for plotting activity levels in a graph. The result is an array of date/count pairs,
    # starting from the earliest day in the collection and all the way to today.
    def datapoints
      grouped = group_by(&:date)
      (last.date..Date.today).map { |date| [date, (grouped[date] || []).size] }
    end
  end

  named_scope :visible_to, lambda { |person| {
    :joins=>'JOIN stakeholders AS involved ON involved.task_id=activities.task_id',
    :conditions=>{ 'involved.person_id'=>person }, :group=>'activities.id'
  } }

  # TODO: test this!
  after_save do |activity|
    activity.task.webhooks.select do |hook|
      hook.send_notification if hook.event == activity.name.to_s
    end
  end

end
