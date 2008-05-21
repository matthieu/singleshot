namespace 'db' do

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
    url = 'http://localhost:3001/sandwich'
    other = Person.identify('anon') || Person.create(:email=>'anon@apache.org')
    Activity.delete_all
    Stakeholder.delete_all
    Task.delete_all
    create = lambda do |attributes|
      attributes = { :title=>Faker::Lorem.sentence, :description=>Faker::Lorem.paragraph,
                     :frame_url=>url, :modified_by=>you }.merge(attributes || {})
      Task.create!(attributes)
    end

    # Tasks you should not see.
    create[:title=>'You will not see this task since this task is reserved.', :status=>'reserved', :creator=>you]
    create[:title=>'You will not see this task since you are not a stakeholder.']
    # Tasks in which we are:
    # - creator
    # - owner
    # - observer
    # - admin
    create[:creator=>you]
    create[:creator=>you, :owner=>you]
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
