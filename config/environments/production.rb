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
