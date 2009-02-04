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


ActionController::Routing::Routes.draw do |map|

  map.resource 'session'
  map.resources 'tasks', :collection=>{ 'completed'=>:get, 'following'=>:get, 'complete_redirect'=>:get },
    :member=>['activities'] do |tasks|
    map.connect '/tasks/:id', :controller=>'tasks', :action=>'complete', :conditions=>{ :method=>:post }
    tasks.with_options :controller=>'task_for' do |opts|
      opts.connect 'for/:person_id', :action=>'update', :conditions=>{ :method=>:put }
      opts.for_person 'for/:person_id', :action=>'show'
    end
  end
  map.search '/search', :controller=>'tasks', :action=>'search'
  map.open_search '/search/osd', :controller=>'tasks', :action=>'opensearch'
 
  map.activity '/activity', :controller=>'activity', :action=>'index'
  #map.formatted_activity '/activity.:format', :controller=>'activity', :action=>'index'
  map.recent_activity '/activity/recent', :controller=>'activity', :action=>'recent'
  
  map.sparklines '/sparklines', :controller=>'sparklines'
  map.root :controller=>'application'

  map.resource 'sandwich'
  map.resource 'survey', :controller=>'survey'

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
