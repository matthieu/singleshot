require 'annotate_models/tasks'

namespace :db do

  desc 'Rebuild the database by running all migrations again'
  task 'rebuild'=>['environment', 'drop', 'create', 'migrate', 'test:clone', 'annotate_models']

  desc 'Populate the database with mock values'
  task 'populate'=>['environment', 'create', 'migrate'] do
    you = Person.find_by_identity(ENV['USER'])
    unless you
      you = Person.create(:email=>"#{ENV['USER']}@apache.org", :password=>'secret')
      puts 'Created an account for you:'
      puts "  Username: #{ENV['USER']}"
      puts '  Password: secret'
    end

    puts "Populating database for #{you.identity}"
    url = 'http://localhost:3001/sandwhich'
    other = Person.identify('anon') || Person.create(:email=>'anon@apache.org')
    create = lambda do |attributes|
      attributes = { :title=>Faker::Lorem.sentence, :description=>Faker::Lorem.paragraph,
                     :frame_url=>url, :state=>'ready' }.merge(attributes || {})
      task = Task.new(attributes)
      task.save(you)
    end
    #create = lambda { |attributes| { :title=>Faker::Lorem.sentence, :description=>Faker::Lorem.paragraph,
    #                                  :frame_url=>url, :state=>'ready' }.merge(attributes || {}) }

    # Tasks you should not see.
    create[:title=>'You will not see this task since this task is reserved.', :state=>'reserved', :creator=>you]
    create[:title=>'You will not see this task since you are not a stakeholder.']
    # Tasks in which we are:
    # - creator
    # - owner
    # - observer
    # - admin
    create[:creator=>you]
    create[:owner=>you]
    create[:observers=>you]
    create[:admins=>you]
    # Tasks in which we are only or one of many potential owners.
    create[:potential_owners=>you]
    create[:potential_owners=>[you, other]]
    create[:owner=>other, :potential_owners=>you]
    # High priority should show first.
    create[:owner=>you, :priority=>Task::PRIORITIES.first]
    # Over-due before due today before anything else.
    create[:owner=>you, :due_on=>Time.today - 1.day]
    create[:owner=>you, :due_on=>Time.today]
    create[:owner=>you, :due_on=>Time.today + 1.day]
  end

end

