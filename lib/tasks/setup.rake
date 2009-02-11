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


require 'rails_generator/secret_key_generator'

file 'secret.key' do |task|
  secret = ActiveSupport::SecureRandom.hex(64)
  File.open task.name, 'w' do |file|
    file.write secret
  end
  puts "Generated new secret in #{task.name}"
end


desc "Run this task first to setup your test/development environment"
task 'setup'=>['gems:install', 'plugins:install', 'secret.key', 'db:create', 'db:test:clone', 'db:populate']


namespace 'plugins' do
  
  desc "Install all the plugins this app depends on"
  task 'install' do
    rb_bin = File.join(Config::CONFIG['bindir'], Config::CONFIG['ruby_install_name'])
    system rb_bin, 'script/plugin', 'install', 'git://github.com/zargony/activerecord_symbolize.git'
    system rb_bin, 'script/plugin', 'install', 'git://github.com/assaf/presenter.git'
  end
  
  desc "List installed plugins"
  task 'list'=>['environment'] do
    plugins = Rails::Initializer.run.loaded_plugins
    plugins.each do |plugin|
      about = plugin.about
      about['path'] = plugin.directory
      puts "#{plugin.name}:"
      width = plugin.about.keys.map(&:size).max
      plugin.about.keys.sort.each do |name|
        puts "  %#{width}s: %s" % [name, plugin.about[name]]
      end
      puts
    end
  end
  
end
