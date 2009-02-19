Given /^the person (.*) exists$/ do |name|
  Person.identify(name) rescue Person.create!(:email=>"#{name}@example.com", :password=>'secret')
end

Given /^a newly created task$/ do
  Given "the person creator exists"
  @task = Person.identify('creator').tasks.create!(:title=>'newly created task')
end

Given /^a newly created task assigned to (.*)$/ do |person|
  Given "the person creator exists"
  Given "the person #{person} exists"
  @task = Person.identify('creator').tasks.create!(:title=>'newly created task', :owner=>Person.identify(person))
end

Given /^owner (.*)$/ do |person|
  Given "the person #{person} exists"
  @task.stakeholders.create! :role=>:owner, :person=>Person.identify(person)
end

Given /^potential owners (.*)$/ do |people|
  people.split(/,\s*/).each do |person|
    Given "the person #{person} exists"
    @task.stakeholders.build :role=>:potential_owner, :person=>Person.identify(person)
  end
  @task.save!
end

Given /^supervisor (.*)$/ do |person|
  Given "the person #{person} exists"
  @task.stakeholders.create! :role=>:supervisor, :person=>Person.identify(person)
end


When /^(.*) claims task$/ do |person|
  person = Person.identify(person)
  person.tasks.find(@task).update_attributes! :owner=>person
end

When /^(.*) delegates task to (.*)$/ do |by, to|
  Person.identify(by).tasks.find(@task).update_attributes! :owner=>Person.identify(to)
end

When /^(.*) releases task$/ do |person|
  Person.identify(person).tasks.find(@task).update_attributes! :owner=>nil
end

When /^(.*) suspends task$/ do |person|
  Person.identify(person).tasks.find(@task).update_attributes! :status=>:suspended
end

When /^(.*) resumes task$/ do |person|
  Person.identify(person).tasks.find(@task).update_attributes! :status=>:active
end

When /^(.*) cancels task$/ do |person|
  Person.identify(person).tasks.find(@task).update_attributes! :status=>:cancelled
end

When /^(.*) completes task$/ do |person|
  Person.identify(person).tasks.find(@task).update_attributes! :status=>:completed
end

When /^(.*) modifies task (.*)$/ do |person, attribute|
  Person.identify(person).tasks.find(@task).update_attributes! attribute=>@task.send(attribute).upcase
end


Then /^activity log should show (.*) (.*) task$/ do |person, name|
  person = Person.identify(person)
  Task.find(@task).activities.any? { |activity| activity.name.to_s == name && activity.person == person } or
    fail "Did not find {#{person.to_param} #{name} '#{@task.title}'}"
end
