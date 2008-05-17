ActionController::Routing::Routes.draw do |map|

  map.resource 'session'
  map.resources 'tasks', :collection=>{ 'following'=>:get, 'completed'=>:get }, :member=>{ 'activity'=>:get }
  map.resources 'activities'
  map.day_activity 'activity/:year/:month/:day', :controller=>'activities', :action=>'show', :year =>/\d{4}/, :month=>/\d{1,2}/, :day=>/\d{1,2}/
  map.root :controller=>'tasks'
  map.resource 'sandwich'
  #map.connect ':controller/:action/:id'
  

  # Authentication resource (create/destroy).

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  # map.resources :products

  # Sample resource route with options:
  # map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  # map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # Install the default routes as the lowest priority.
end
