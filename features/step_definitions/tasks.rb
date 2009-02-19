Given /^the person (\S*) exists$/ do |name|
  Person.identify(name) rescue Person.create!(:email=>"#{name}@example.com", :password=>'secret')
end

Given /^a newly created task "(.*)"$/ do |title|
  Given "the person creator exists"
  Person.identify('creator').tasks.create!(:title=>title)
end

Given /^a newly created task "(.*)" assigned to (\S*)$/ do |title, person|
  Given "the person creator exists"
  Given "the person #{person} exists"
  Person.identify('creator').tasks.create!(:title=>title, :owner=>Person.identify(person))
end

Given /^owner (\S*) for "(.*)"$/ do |person, title|
  Given "the person #{person} exists"
  Task.find_by_title(title).stakeholders.create! :role=>:owner, :person=>Person.identify(person)
end

Given /^potential owners (.*) for "(.*)"$/ do |people, title|
  task = Task.find_by_title(title)
  people.split(/,\s*/).each do |person|
    Given "the person #{person} exists"
    task.stakeholders.build :role=>:potential_owner, :person=>Person.identify(person)
  end
  task.save!
end

Given /^supervisor (\S*) for "(.*)"$/ do |person, title|
  Given "the person #{person} exists"
  Task.find_by_title(title).stakeholders.create! :role=>:supervisor, :person=>Person.identify(person)
end


When /^(\S*) claims task "(.*)"$/ do |person, title|
  task = Person.identify(person).tasks.find(:first, :conditions=>{:title=>title})
  task.update_attributes! :owner=>Person.identify(person)
end

When /^(\S*) delegates task "(.*)" to (\S*)$/ do |person, title, designated|
  task = Person.identify(person).tasks.find(:first, :conditions=>{:title=>title})
  task.update_attributes! :owner=>Person.identify(designated)
end

When /^(\S*) releases task "(.*)"$/ do |person, title|
  task = Person.identify(person).tasks.find(:first, :conditions=>{:title=>title})
  task.update_attributes! :owner=>nil
end

When /^(\S*) suspends task "(.*)"$/ do |person, title|
  task = Person.identify(person).tasks.find(:first, :conditions=>{:title=>title})
  task.update_attributes! :status=>:suspended
end

When /^(\S*) resumes task "(.*)"$/ do |person, title|
  task = Person.identify(person).tasks.find(:first, :conditions=>{:title=>title})
  task.update_attributes! :status=>:active
end

When /^(\S*) cancels task "(.*)"$/ do |person, title|
  task = Person.identify(person).tasks.find(:first, :conditions=>{:title=>title})
  task.update_attributes! :status=>:cancelled
end

When /^(\S*) completes task "(.*)"$/ do |person, title|
  task = Person.identify(person).tasks.find(:first, :conditions=>{:title=>title})
  task.update_attributes! :status=>:completed
end

When /^(\S*) modifies (\S*) of task "(.*)" to (.*)$/ do |person, attribute, title, value|
  task = Person.identify(person).tasks.find(:first, :conditions=>{:title=>title})
  task.update_attributes! attribute=>value
end


Then /^activity log should show (\S*) (\S*) "(.*)"$/ do |person, name, title|
  person = Person.identify(person)
  Task.find_by_title(title).activities.any? { |activity| activity.name.to_s == name && activity.person == person } or
    fail "Did not find {#{person.to_param} #{name} "#{title}"}"
end
