config.cache_classes = true
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_view.cache_template_loading            = true
 

# config.cache_store = :mem_cache_store
# config.action_controller.asset_host = "http://assets.example.com"
# config.action_mailer.raise_delivery_errors = false


# Setting this flag allows concurrent requests handling, useful for JRuby in
# production, not so much anywhere else.  We do support it, so pay attention.
# Automatic loading doesn't work well since require is not atomic, so pay
# attention and require everything during initialization, specifically everything
# in lib (Rails takes care of app and plugins).
config.threadsafe!
config.eager_load_paths << "#{RAILS_ROOT}/lib"
