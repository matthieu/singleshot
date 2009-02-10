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
#== Route Map
# Generated on 09 Feb 2009 17:41
#
#             new_session GET    /session/new(.:format)             {:action=>"new", :controller=>"sessions"}
#            edit_session GET    /session/edit(.:format)            {:action=>"edit", :controller=>"sessions"}
#                 session GET    /session(.:format)                 {:action=>"show", :controller=>"sessions"}
#                         PUT    /session(.:format)                 {:action=>"update", :controller=>"sessions"}
#                         DELETE /session(.:format)                 {:action=>"destroy", :controller=>"sessions"}
#                         POST   /session(.:format)                 {:action=>"create", :controller=>"sessions"}
#         completed_tasks GET    /tasks/completed(.:format)         {:action=>"completed", :controller=>"tasks"}
# complete_redirect_tasks GET    /tasks/complete_redirect(.:format) {:action=>"complete_redirect", :controller=>"tasks"}
#         following_tasks GET    /tasks/following(.:format)         {:action=>"following", :controller=>"tasks"}
#                   tasks GET    /tasks(.:format)                   {:action=>"index", :controller=>"tasks"}
#                         POST   /tasks(.:format)                   {:action=>"create", :controller=>"tasks"}
#                new_task GET    /tasks/new(.:format)               {:action=>"new", :controller=>"tasks"}
#               edit_task GET    /tasks/:id/edit(.:format)          {:action=>"edit", :controller=>"tasks"}
#         activities_task        /tasks/:id/activities(.:format)    {:action=>"activities", :controller=>"tasks"}
#                    task GET    /tasks/:id(.:format)               {:action=>"show", :controller=>"tasks"}
#                         PUT    /tasks/:id(.:format)               {:action=>"update", :controller=>"tasks"}
#                         DELETE /tasks/:id(.:format)               {:action=>"destroy", :controller=>"tasks"}
#                         POST   /tasks/:id                         {:action=>"complete", :controller=>"tasks"}
#                         PUT    /tasks/:task_id/for/:person_id     {:action=>"update", :controller=>"task_for"}
#         task_for_person        /tasks/:task_id/for/:person_id     {:action=>"show", :controller=>"task_for"}
#                  search        /search                            {:action=>"search", :controller=>"tasks"}
#             open_search        /search/osd                        {:action=>"opensearch", :controller=>"tasks"}
#                activity        /activity                          {:action=>"index", :controller=>"activity"}
#         recent_activity        /activity/recent                   {:action=>"recent", :controller=>"activity"}
#              sparklines        /sparklines                        {:action=>"index", :controller=>"sparklines"}
#                    root        /                                  {:action=>"index", :controller=>"application"}
#            new_sandwich GET    /sandwich/new(.:format)            {:action=>"new", :controller=>"sandwiches"}
#           edit_sandwich GET    /sandwich/edit(.:format)           {:action=>"edit", :controller=>"sandwiches"}
#                sandwich GET    /sandwich(.:format)                {:action=>"show", :controller=>"sandwiches"}
#                         PUT    /sandwich(.:format)                {:action=>"update", :controller=>"sandwiches"}
#                         DELETE /sandwich(.:format)                {:action=>"destroy", :controller=>"sandwiches"}
#                         POST   /sandwich(.:format)                {:action=>"create", :controller=>"sandwiches"}
#              new_survey GET    /survey/new(.:format)              {:action=>"new", :controller=>"survey"}
#             edit_survey GET    /survey/edit(.:format)             {:action=>"edit", :controller=>"survey"}
#                  survey GET    /survey(.:format)                  {:action=>"show", :controller=>"survey"}
#                         PUT    /survey(.:format)                  {:action=>"update", :controller=>"survey"}
#                         DELETE /survey(.:format)                  {:action=>"destroy", :controller=>"survey"}
#                         POST   /survey(.:format)                  {:action=>"create", :controller=>"survey"}
#                                /:controller/:action/:id           
#                                /:controller/:action/:id(.:format) 
