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


# Be sure to restart your web server when you modify this file.

ENV['RAILS_ENV'] ||= 'production'
RAILS_GEM_VERSION = '2.2.2' unless defined? RAILS_GEM_VERSION
# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')


Rails::Initializer.run do |config|
  config.gem 'rest-open-uri',                   :version=>'~>1.0'
  config.gem 'rmagick', :lib=>'RMagick',        :version=>'~>2.7'
  config.gem 'sparklines',                      :version=>'~>0.5'
  #config.gem 'acts_as_ferret',                  :version=>'~>0.4'
  config.gem 'mislav-will_paginate', :lib=>'will_paginate',
    :source=>'http://gems.github.com',          :version=>'~>2.3'

  config.plugins = [:all]
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  config.time_zone = 'UTC'

  config.action_controller.use_accept_header = true
  config.action_controller.session = {
    :session_key => '_singleshot_session',
    :secret      => File.read("#{Rails.root}/secret.key")
  }

  config.active_record.schema_format = :sql
  config.active_record.partial_updates = true
  # config.active_record.observers = :cacher, :garbage_collector
  
  # These settings change the behavior of Rails 2 apps and will be defaults
  # for Rails 3. You can remove this initializer when Rails 3 is released.
  config.active_record.include_root_in_json = true
  config.active_record.store_full_sti_class = true
  config.active_support.use_standard_json_time_format = true
  config.active_support.escape_html_entities_in_json = false

  # The internationalization framework can be changed 
  # to have another default locale (standard is :en) or more load paths.
  # All files from config/locales/*.rb,yml are added automatically.
  # config.i18n.load_path << Dir[File.join(RAILS_ROOT, 'my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
  
end
