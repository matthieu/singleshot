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

  map.resources 'forms'
  map.resources 'activities'
  
  map.root :controller=>'tasks', :action=>'index'

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
#== Route Map
# Generated on 01 Mar 2009 01:31
#
#             new_session GET    /session/new(.:format)             {:controller=>"sessions", :action=>"new"}
#            edit_session GET    /session/edit(.:format)            {:controller=>"sessions", :action=>"edit"}
#                 session GET    /session(.:format)                 {:controller=>"sessions", :action=>"show"}
#                         PUT    /session(.:format)                 {:controller=>"sessions", :action=>"update"}
#                         DELETE /session(.:format)                 {:controller=>"sessions", :action=>"destroy"}
#                         POST   /session(.:format)                 {:controller=>"sessions", :action=>"create"}
#         completed_tasks GET    /tasks/completed(.:format)         {:controller=>"tasks", :action=>"completed"}
# complete_redirect_tasks GET    /tasks/complete_redirect(.:format) {:controller=>"tasks", :action=>"complete_redirect"}
#         following_tasks GET    /tasks/following(.:format)         {:controller=>"tasks", :action=>"following"}
#                   tasks GET    /tasks(.:format)                   {:controller=>"tasks", :action=>"index"}
#                         POST   /tasks(.:format)                   {:controller=>"tasks", :action=>"create"}
#                new_task GET    /tasks/new(.:format)               {:controller=>"tasks", :action=>"new"}
#               edit_task GET    /tasks/:id/edit(.:format)          {:controller=>"tasks", :action=>"edit"}
#         activities_task        /tasks/:id/activities(.:format)    {:controller=>"tasks", :action=>"activities"}
#                    task GET    /tasks/:id(.:format)               {:controller=>"tasks", :action=>"show"}
#                         PUT    /tasks/:id(.:format)               {:controller=>"tasks", :action=>"update"}
#                         DELETE /tasks/:id(.:format)               {:controller=>"tasks", :action=>"destroy"}
#                         POST   /tasks/:id                         {:controller=>"tasks", :action=>"complete"}
#                         PUT    /tasks/:task_id/for/:person_id     {:controller=>"task_for", :action=>"update"}
#         task_for_person        /tasks/:task_id/for/:person_id     {:controller=>"task_for", :action=>"show"}
#                  search        /search                            {:controller=>"tasks", :action=>"search"}
#             open_search        /search/osd                        {:controller=>"tasks", :action=>"opensearch"}
#              activities GET    /activities(.:format)              {:controller=>"activities", :action=>"index"}
#                         POST   /activities(.:format)              {:controller=>"activities", :action=>"create"}
#            new_activity GET    /activities/new(.:format)          {:controller=>"activities", :action=>"new"}
#           edit_activity GET    /activities/:id/edit(.:format)     {:controller=>"activities", :action=>"edit"}
#                activity GET    /activities/:id(.:format)          {:controller=>"activities", :action=>"show"}
#                         PUT    /activities/:id(.:format)          {:controller=>"activities", :action=>"update"}
#                         DELETE /activities/:id(.:format)          {:controller=>"activities", :action=>"destroy"}
#                    root        /                                  {:controller=>"application", :action=>"index"}
#                                /:controller/:action/:id           
#                                /:controller/:action/:id(.:format) 
