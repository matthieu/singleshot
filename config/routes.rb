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
    tasks.with_options :controller=>'task_for' do |opts|
      opts.connect 'for/:person_id', :action=>'update', :conditions=>{ :method=>:put }
      opts.for_person 'for/:person_id', :action=>'show'
    end
  end
  map.connect '/tasks/:id', :controller=>'tasks', :action=>'update', :conditions=>{ :method=>:post }

  map.search '/search', :controller=>'tasks', :action=>'search'
  map.open_search '/search/osd', :controller=>'tasks', :action=>'opensearch'

  map.resources 'forms'
  map.resources 'templates'
  map.resources 'notifications'
  map.resources 'activities'
  map.resource  'graphs'
  
  map.root :controller=>'tasks', :action=>'index'

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
#== Route Map
# Generated on 13 May 2009 14:13
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
#         activities_task        /tasks/:id/activities(.:format)    {:action=>"activities", :controller=>"tasks"}
#               edit_task GET    /tasks/:id/edit(.:format)          {:action=>"edit", :controller=>"tasks"}
#                    task GET    /tasks/:id(.:format)               {:action=>"show", :controller=>"tasks"}
#                         PUT    /tasks/:id(.:format)               {:action=>"update", :controller=>"tasks"}
#                         DELETE /tasks/:id(.:format)               {:action=>"destroy", :controller=>"tasks"}
#                         PUT    /tasks/:task_id/for/:person_id     {:action=>"update", :controller=>"task_for"}
#         task_for_person        /tasks/:task_id/for/:person_id     {:action=>"show", :controller=>"task_for"}
#                         POST   /tasks/:id                         {:action=>"update", :controller=>"tasks"}
#                  search        /search                            {:action=>"search", :controller=>"tasks"}
#             open_search        /search/osd                        {:action=>"opensearch", :controller=>"tasks"}
#                   forms GET    /forms(.:format)                   {:action=>"index", :controller=>"forms"}
#                         POST   /forms(.:format)                   {:action=>"create", :controller=>"forms"}
#                new_form GET    /forms/new(.:format)               {:action=>"new", :controller=>"forms"}
#               edit_form GET    /forms/:id/edit(.:format)          {:action=>"edit", :controller=>"forms"}
#                    form GET    /forms/:id(.:format)               {:action=>"show", :controller=>"forms"}
#                         PUT    /forms/:id(.:format)               {:action=>"update", :controller=>"forms"}
#                         DELETE /forms/:id(.:format)               {:action=>"destroy", :controller=>"forms"}
#               templates GET    /templates(.:format)               {:action=>"index", :controller=>"templates"}
#                         POST   /templates(.:format)               {:action=>"create", :controller=>"templates"}
#            new_template GET    /templates/new(.:format)           {:action=>"new", :controller=>"templates"}
#           edit_template GET    /templates/:id/edit(.:format)      {:action=>"edit", :controller=>"templates"}
#                template GET    /templates/:id(.:format)           {:action=>"show", :controller=>"templates"}
#                         PUT    /templates/:id(.:format)           {:action=>"update", :controller=>"templates"}
#                         DELETE /templates/:id(.:format)           {:action=>"destroy", :controller=>"templates"}
#           notifications GET    /notifications(.:format)           {:action=>"index", :controller=>"notifications"}
#                         POST   /notifications(.:format)           {:action=>"create", :controller=>"notifications"}
#        new_notification GET    /notifications/new(.:format)       {:action=>"new", :controller=>"notifications"}
#       edit_notification GET    /notifications/:id/edit(.:format)  {:action=>"edit", :controller=>"notifications"}
#            notification GET    /notifications/:id(.:format)       {:action=>"show", :controller=>"notifications"}
#                         PUT    /notifications/:id(.:format)       {:action=>"update", :controller=>"notifications"}
#                         DELETE /notifications/:id(.:format)       {:action=>"destroy", :controller=>"notifications"}
#              activities GET    /activities(.:format)              {:action=>"index", :controller=>"activities"}
#                         POST   /activities(.:format)              {:action=>"create", :controller=>"activities"}
#            new_activity GET    /activities/new(.:format)          {:action=>"new", :controller=>"activities"}
#           edit_activity GET    /activities/:id/edit(.:format)     {:action=>"edit", :controller=>"activities"}
#                activity GET    /activities/:id(.:format)          {:action=>"show", :controller=>"activities"}
#                         PUT    /activities/:id(.:format)          {:action=>"update", :controller=>"activities"}
#                         DELETE /activities/:id(.:format)          {:action=>"destroy", :controller=>"activities"}
#              new_graphs GET    /graphs/new(.:format)              {:action=>"new", :controller=>"graphs"}
#             edit_graphs GET    /graphs/edit(.:format)             {:action=>"edit", :controller=>"graphs"}
#                  graphs GET    /graphs(.:format)                  {:action=>"show", :controller=>"graphs"}
#                         PUT    /graphs(.:format)                  {:action=>"update", :controller=>"graphs"}
#                         DELETE /graphs(.:format)                  {:action=>"destroy", :controller=>"graphs"}
#                         POST   /graphs(.:format)                  {:action=>"create", :controller=>"graphs"}
#                    root        /                                  {:action=>"index", :controller=>"tasks"}
#                                /:controller/:action/:id           
#                                /:controller/:action/:id(.:format) 
