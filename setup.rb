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


require 'rubygems'
require 'rake'


# The plugins we maintain in vendor/plugins.
$plugins = 'git://github.com/assaf/presenter.git',
           'git://github.com/zargony/activerecord_symbolize.git'


def check(message)
  if Rake.application.tty_output?
    message = message[0, Rake.application.dynamic_width - 9]
    print("[ ]  %s ... " % message)
    $stdout.flush
    pos = $stdout.pos, $stderr.pos
  end
  yield
  print "\r" if pos == [$stdout.pos, $stderr.pos]
  print "[x]  #{message}\n"
end

def rake(*args)
  ruby "-S rake --silent #{args.map { |arg| arg.inspect }.join(' ')}"
end


namespace 'setup' do

  task 'run'=>['dependencies', 'files', 'database'] do
    Rake::Task['setup:have_fun'].invoke
  end

  task 'dependencies' do
    check("Installing Rails 2.3.0") { ruby "-S gem install rails -v 2.3.0" }
    check("Installing missing gem dependencies") { rake "gems:install" }
    check "Installing/upgrading plugins" do
      $plugins.each do |url|
        name, path = url.pathmap('%n'), url.pathmap('vendor/plugins/%n')
        if Dir["#{path}/*"].empty?
          ruby "script/plugin install #{url}"
          fail "Plugin #{name} not installed! (looked for it in #{path})" if Dir["#{path}/*"].empty?
        else
          ruby "script/plugin update #{name}"
        end
      end
    end
  end

  task 'files' do
    check("Creating new secret key in secret.key") { rake 'secret.key' }
  end

  task 'database' do
    check("Creating a new database")                         { rake "db:create" }
    check("Running all migrations against the new database") { rake "db:migrate:reset" }
    check("Creating a clone test database")                  { rake "db:test:clone" }
    check("Populating development database with mock data")  { rake "db:populate" }
  end

  task 'have_fun' do
    puts <<-TEXT

Done!


   (  (
    )  )
 |_______|--|
 |       |  |
 |       |_/
  \\_____/
 

Delicously fresh ascii coffee, on the house.

To start the server:
  ./script/server

Next, open http://localhost:3000 in your browser and login with
  username:  #{ENV['USER']}
  password:  secret

Have fun!

    TEXT
  end
end

Rake::Task['setup:run'].invoke
