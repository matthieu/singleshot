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


class PopulateDatabase
    
  def populate
    Activity.delete_all
    Stakeholder.delete_all
    Task.delete_all
    Person.delete_all
    
    puts "Populating database for #{you.identity}"

    # Tasks you should not see.
    new_task 
    # Tasks in which we are:
    # - creator
    # - owner
    # - observer
    # - admin
    new_task.associate! :creator=>you
    new_task.associate! :creator=>you
    you.update_task! Task.last, :owner=>you
    new_task.associate! :observer=>you
    new_task.associate! :supervisor=>you
    # Tasks in which we are only or one of many potential owners.
    new_task.associate! :potential_owner=>you
    new_task.associate! :potential_owner=>[you, other]
    Task.last.update_attributes! :owner=>other
    # High priority should show first.
    new_task(:priority=>Task::PRIORITY.first).associate! :owner=>you
    # Over-due before due today before anything else.
    new_task(:due_on=>Date.current - 1.day).associate! :owner=>you
    new_task(:due_on=>Date.current).associate! :owner=>you
    new_task(:due_on=>Date.current + 1.day).associate! :owner=>you
    # Completed, cancelled, suspended
    new_task.associate! :potential_owner=>[you, other], :supervisor=>other
    other.update_task! Task.last, :status=>'suspended'
    new_task.associate! :owner=>you
    you.update_task! Task.last, :status=>'completed'
    new_task.associate! :supervisor=>you
    you.update_task! Task.last, :status=>'cancelled'
  end
    
protected
  
  def you
    @you ||= begin
      Person.identify(ENV['USER'])
    rescue
      puts "Creating an account for you:"
      puts "  Username: #{ENV['USER']}"
      puts "  Password: secret"
      Person.create! :email=>"#{ENV['USER']}@example.com", :password=>'secret'
    end
  end
  
  def other
    @other ||= begin
      Person.identify('anon')
    rescue
      Person.create! :email=>'anon@example.com'
    end
  end

  def new_task(attributes = nil)
    #delay
    Task.create! attributes do |task|
      task.title ||= Faker::Lorem.sentence
      task.description ||= Faker::Lorem.paragraphs(3).join("\n\n")
      task.associate :potential_owner=>[you, other]
    end
  end

  def self.delay(duration = 2.hours)
    [Task, Stakeholder, Activity].each do |model|
      model.all.each do |record|
        change = ['created_at = :time', {:time=>record.created_at - duration}]
        if record.respond_to?(:updated_at)
          change.first << ', updated_at = :time'
          #change << record.updated_at - duration
        end
        model.update_all change, :id=>record.id
      end
    end
  end

end
