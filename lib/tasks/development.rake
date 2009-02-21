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


desc 'Populate the database with mock values'
task 'db:populate'=>['environment', 'db:create', 'db:migrate'] do
  load Rails.root + 'db/populate.rb'
  Populate.down
  Populate.up
end


desc "List installed plugins"
task 'plugins:list'=>['environment'] do
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
