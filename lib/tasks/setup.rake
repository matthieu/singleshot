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


task 'setup' do
  puts <<-TEXT
    rake setup was a nice idea, but suffered from the classical bootstrapping issue (aka catch-22).
    So instead, the new way to setup Singleshot is to run:
      ruby ./script/setup

    Like this ...  

  TEXT
  ruby "setup.rb"
end
