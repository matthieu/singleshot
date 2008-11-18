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

task 'secret.key' do |task|
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
#    system 'rb_bin', 'script/plugin', 'git://github.com/dchelimsky/rspec-rails.git'  
  end
  
  desc "List installed plugins"
  task 'list' do
    plugins = Dir["#{Rails.root}/vendor/plugins/*"].map { |path| Rails::Plugin.new(path) }
    plugins.each do |plugin|
      puts "Plugin: #{plugin.name}\n(#{plugin.directory})"
      width = plugin.about.keys.map(&:size).max
      plugin.about.each do |key, value|
        puts "  %#{width}s: %s" % [key, value]
      end
      puts
    end
  end
  
end
