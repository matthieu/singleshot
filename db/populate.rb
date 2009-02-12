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


Task.blueprint do
  title           { Faker::Lorem.sentence }
  description     { Faker::Lorem.paragraphs(3).join("\n\n") }
  object.associate :potential_owner=>[Person.identify(ENV['USER']), Person.identify('other')]
end

Person.blueprint do
end


# This is a special migration that populates the database with one usable
# account and a lot of fake tasks. Gets you going when you first install
# Singleshot and wondering how to use it. Run using +rake db:populate+.
class Populate < ActiveRecord::Migration
  def self.up
    puts "Creating an account for:"
    puts "  Username: #{ENV['USER']}"
    puts "  Password: secret"
    me = Person.make(:email=>"#{ENV['USER']}@example.com", :password=>'secret')

    puts "Populating database for #{me.to_param}"
    other = Person.make(:email=>"other@example.com")

    # Tasks I should not see.
    Task.make 
    # Tasks in which we are:
    # - creator
    # - owner
    # - observer
    # - admin
    Task.make.associate! :creator=>me
    Task.make.associate! :creator=>me
    me.update_task! Task.last, :owner=>me
    Task.make.associate! :observer=>me
    Task.make.associate! :supervisor=>me
    # Tasks in which we are only or one of many potential owners.
    Task.make.associate! :potential_owner=>me
    Task.make.associate! :potential_owner=>[me, other]
    Task.last.update_attributes! :owner=>other
    # High priority should show first.
    Task.make(:priority=>Task::PRIORITY.first).associate! :owner=>me
    # Over-due before due today before anything else.
    Task.make(:due_on=>Date.current - 1.day).associate! :owner=>me
    Task.make(:due_on=>Date.current).associate! :owner=>me
    Task.make(:due_on=>Date.current + 1.day).associate! :owner=>me
    # Completed, cancelled, suspended
    Task.make.associate! :potential_owner=>[me, other], :supervisor=>other
    other.update_task! Task.last, :status=>'suspended'
    Task.make.associate! :owner=>me
    me.update_task! Task.last, :status=>'completed'
    Task.make.associate! :supervisor=>me
    me.update_task! Task.last, :status=>'cancelled'
  end

  def self.down
    Activity.delete_all
    Stakeholder.delete_all
    Task.delete_all
    Person.delete_all
  end
    
end
