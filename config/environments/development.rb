# Singleshot
# Copyright (C) 2008-2009  Intalio, Inc
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


config.cache_classes = false
config.whiny_nils = true
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false
config.action_mailer.raise_delivery_errors = false

# Annotate models and routes.
config.gem 'annotate',          :version=>'~>2.0', :lib=>false
# RSpec and Cucumber for BDD.
config.gem 'rspec-rails',       :version=>'1.2.4', :lib=>false
config.gem 'cucumber',          :version=>'0.3.0', :lib=>false
config.gem 'webrat',            :version=>'0.4.4', :lib=>false
config.gem 'remarkable_rails',  :version=>'3.0.7', :lib=>false
# Fake data and blueprint models.
config.gem 'faker',             :version=>'0.3.1', :lib=>false
config.gem 'notahat-machinist', :version=>'0.3.1', :lib=>false

# To enable Rack::Bug get the bookmarklet from http://localhost:3000/__rack_bug__/bookmarklet.html
#config.middleware.use 'Rack::Bug'
