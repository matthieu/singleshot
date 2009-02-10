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


config.cache_classes = false
config.whiny_nils = true
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false
config.action_mailer.raise_delivery_errors = false


# These Gems are used exclusively during development/testing, they're listed here
# to be included when running rake setup. Some of these are only used from rake
# tasks or command line (e.g. rspec, thin), so don't load them as part of Rails.
=begin
config.gem 'rspec-rails',   :version=>'1.1.12',
  :source=>'http://gems.rubyforge.org', :lib=>false
config.gem 'annotate',      :version=>'~>2.0.1',  # Used for annotating models with database schema (rake db:annotate)
  :source=>'http://gems.rubyforge.org', :lib=>false
config.gem 'faker',         :version=>'~>0.3',    # Used to populate development database with fake data (rake db:populate)
  :source=>'http://gems.rubyforge.org', :lib=>false
config.gem 'thin',          :version=>'~>1.0',    # Not essential, but development scripts (e.g. rake run) are hard wired to use Thin.
  :source=>'http://gems.rubyforge.org', :lib=>false
config.gem 'sqlite3-ruby',  :version=>'~>1.2',    # Development and test databases use SQLite3 by default. 
  :source=>'http://gems.rubyforge.org', :lib=>'sqlite3'
=end
