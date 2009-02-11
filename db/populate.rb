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
