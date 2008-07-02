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

  def readonly? #:nodoc:
    !new_record?
  end

  # Returns activities from all tasks associated with this stakeholder.
  named_scope :for_stakeholder, lambda { |person|
    { :joins=>'JOIN stakeholders AS involved ON involved.task_id=activities.task_id',
      :conditions=>["involved.person_id=? AND involved.role != 'excluded'", person.id],
      :order=>'activities.created_at DESC', :group=>'activities.task_id, activities.person_id, activities.name' } }

  named_scope :with_dependents, :include=>[:task, :person]

  named_scope :for_dates, lambda { |range|
    case range
    when Date
      range = range.to_time..Time.current.end_of_day
    when Range
      range = range.min.to_time.beginning_of_day..range.max.to_time.end_of_day
    end
    { :conditions=>{ :created_at=>range } } }

end
