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

  def index
    @title = I18n.t('activity.index.title')
    @subtitle = I18n.t('activity.index.subtitle')
    for_stakeholder = Activity.for_stakeholder(authenticated)
    @activities = for_stakeholder.with_dependents.paginate(:page=>params['page'], :per_page=>50)
    respond_to do |want|
      want.html do
        @atom_feed_url = formatted_activity_url(:format=>:atom, :access_key=>authenticated.access_key)
        @next = activity_url(:page=>@activities.next_page) if @activities.next_page
        @previous = activity_url(:page=>@activities.previous_page) if @activities.previous_page
        @graph = for_stakeholder.for_dates(Date.current - 1.month)
      end
      want.atom { @root_url = activity_url }
      want.json { render :json=>presenting(@activities) }
      want.xml { render :xml=>presenting(@activities) }
    end
  end

end
