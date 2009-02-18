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
    install = lambda do |url|
      sh rb_bin, 'script/plugin', 'install', url
      path = url.pathmap("vendor/plugins/%n")
      fail "Plugin #{path} not installed!" unless File.directory?(path)
    end
    install.call 'git://github.com/zargony/activerecord_symbolize.git'
    install.call 'git://github.com/assaf/presenter.git'
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
