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


require 'faker'
require 'task'
require 'person'

class Task
  # Associate peoples with roles. Returns self. For example:
  #   task.associate :owner=>"john.smith"
  #   task.associate :observer=>observers
  # Note: all previous associations with the given role are replaced.
  def associate(map)
    map.each do |role, identities|
      new_set = [identities].flatten.compact.map { |id| Person.identify(id) }
      keeping = stakeholders.select { |sh| sh.role == role }
      stakeholders.delete keeping.reject { |sh| new_set.include?(sh.person) }
      (new_set - keeping.map(&:person)).each { |person| stakeholders.build :person=>person, :role=>role }
    end
    self
  end

  def associate!(map)
    associate map
    save!
  end
end


# This is a special migration that populates the database with one usable
# account and a lot of fake tasks. Gets you going when you first install
# Singleshot and wondering how to use it. Run using +rake db:populate+.
class Populate < ActiveRecord::Migration
  def self.up
    puts "Creating an account for:"
    puts "  Username: #{ENV['USER']}"
    puts "  Password: secret"
    @me = Person.create!(:email=>"#{ENV['USER']}@example.com", :password=>'secret')

    puts "Populating database for #{@me.to_param}"
    @bond = Person.create!(:email=>"bond@example.com", :fullname=>"Mr.Bond")

    # Tasks I should not see.
    #Task.make 
    # Tasks in which we are:
    # - creator
    # - owner
    # - observer
    # - admin
    new_task! :creator=>@me
    new_task! :creator=>@me
    advance
    @me.tasks.last.update_attributes! :owner=>@me
    new_task! :observer=>@me
    new_task! :supervisor=>@me
    # Tasks in which we are only or one of many potential owners.
    new_task! :potential_owner=>@me
    new_task! :potential_owner=>[@me, @bond]
    advance
    Task.last.update_attributes! :owner=>@bond
    # High priority should show first.
    new_task! :priority=>Task::PRIORITY.first, :owner=>@me
    # Over-due before due today before anything else.
    new_task! :due_on=>Date.current - 1.day, :owner=>@me
    new_task! :due_on=>Date.current, :owner=>@me
    new_task! :due_on=>Date.current + 1.day, :owner=>@me
    # Completed, cancelled, suspended
    new_task! :potential_owner=>[@me, @bond], :supervisor=>@bond
    advance
    @bond.tasks.last.update_attributes! :status=>'suspended'
    new_task! :owner=>@me
    advance
    @me.tasks.last.update_attributes! :status=>'completed'
    advance
    new_task! :supervisor=>@me
    @me.tasks.last.update_attributes! :status=>'cancelled'

    Template.create! :title=>'Absence request', :description=>'Request leave of absence', :potential_owners=>[@me] do |template|
      template.build_form :html=>"<input name='data[date]' type='text' class='date'>"
    end
    5.times do
      task = Task.all[rand(Task.count * 2)]
      Notification.create! :subject=>Faker::Lorem.sentence, :body=>Faker::Lorem.paragraphs(5).join("\n\n"),
                                   :creator=>task && task.owner, :task=>task, :recipients=>[@me]
    end
  end

  def self.down
    Activity.delete_all
    Stakeholder.delete_all
    Task.delete_all
    Person.delete_all
  end

  FORM = <<-HTML
  <p>{{ owner.fullname }}, please update your contact info:</p>
  <dl>
    <dt>Phone:</dt><dd><input name='data[phone]' size='40' type='text'></dd>
    <dt>Address:</dt><dd><textarea name='data[address]' cols='40' rows='4'></textarea></dd>
    <dt>E-mail:</dt><dd><input name='data[email]' size='40' type='text'></dd>
    <dt>D.O.B:</dt><dd><input name='data[dob]' type='text' class='date'></dd>
  </dl>
  HTML

  def self.new_task!(args = {})
    advance
    args[:title] ||= Faker::Lorem.sentence
    args[:description] ||= Faker::Lorem.paragraphs(3).join("\n\n")
    Task.new args do |task|
      args[:potential_owner] ||= [@me, @bond]
      [:potential_owner, :excluded_owner, :supervisor, :observer].select { |role| args.has_key?(role) }.each do |role|
        Array(args[role]).each do |person|
          task.stakeholders.build :role=>role.to_s, :person=>person
        end
      end
      task.build_form :html=>FORM
    end.save!
  end

  def self.advance(duration = (rand(45) + 30).minutes)
    Task.all.each do |task|
      Task.update_all({:created_at=>task.created_at - duration, :updated_at=>task.updated_at - duration}, {:id=>task.id})
    end
    Activity.all.each do |activity|
      Activity.update_all({:created_at=>activity.created_at - duration}, {:id=>activity.id})
    end
  end
      
end
