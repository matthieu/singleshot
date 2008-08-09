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


class ActivityController < ApplicationController

  access_key_authentication

  def index
    @title = 'Activities'
    @subtitle = 'Track activity in tasks you participate in or observe.'
    @alternate = { Mime::HTML=>activity_url,
                   Mime::ATOM=>formatted_activity_url(:format=>:atom, :access_key=>authenticated.access_key),
                   Mime::ICS=>formatted_activity_url(:format=>:ics, :access_key=>authenticated.access_key) }
    @activities = Activity.for_stakeholder(authenticated).with_dependents.paginate(:page=>params['page'], :per_page=>50)
    respond_to do |want|
      want.html do
        @graph = Activity.for_stakeholder(authenticated).for_dates(Date.current - 1.month)
      end
      want.atom
      want.ics
    end
  end

  def for_task
    @task = Task.for_stakeholder(authenticated).find(params[:task_id], :include=>:activities)
    @activities = @task.activities
    @title = "Activities - #{@task.title}"
    @subtitle = "Track all activities in the task #{@task.title}"
    @alternate = { Mime::HTML=>task_activity_url(@task),
                   Mime::ATOM=>formatted_task_activity_url(@task, :format=>:atom, :access_key=>authenticated.access_key),
                   Mime::ICS=>formatted_task_activity_url(@task, :format=>:ics, :access_key=>authenticated.access_key) }
    respond_to do |want|
      want.html { @graph = @activities ; render :action=>'index' }
      want.atom { render :action=>'index' }
      want.ics  { render :action=>'index' }
    end
  end

end
