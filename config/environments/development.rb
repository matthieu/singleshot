# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

config.action_controller.allow_concurrency = true

# These Gems are used for development.
config.gem 'annotate-models', :lib=>'annotate_models'
config.gem 'rspec', :lib=>'spec',                     :version=>'~> 1.1.3'
# Faker: Used to populate development database with fake data.
config.gem 'faker',                                   :version=>'~>0.3'
# SQLite3: Development and test databases use SQLite3 by default.
config.gem 'sqlite3-ruby', :lib=>'sqlite3',           :version=>'~>1.2'
# Thin: Not essential, but development scripts (e.g. rake run) are hard wired to use Thin.
config.gem 'thin',                                    :version=>'~>0.8'
