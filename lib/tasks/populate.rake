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
    Activity.delete_all
    Stakeholder.delete_all
    Task.delete_all

    def other
      Person.identify('anon') || Person.create(:email=>'anon@apache.org')
    end
    def Task.delay(duration = 2.hours)
      for model in [Task, Stakeholder, Activity]
        model.all.each do |record|
          change = ['created_at = ?', record.created_at - duration]
          if record.respond_to?(:updated_at)
            change.first << ', updated_at = ?'
            change << record.updated_at - duration
          end
          model.update_all change, :id=>record.id 
        end
      end
    end

    def create(attributes)
      Task.delay 
      you = Person.find_by_identity(ENV['USER']) 
      defaults = { :title=>Faker::Lorem.sentence, :description=>Faker::Lorem.paragraphs(3).join("\n\n"),
                   :rendering=>{ :perform_url=>'http://localhost:3001/sandwich', :completing=>true }, :potential_owners=>[you, other] }
      returning Task.new(defaults.merge(attributes || {})) do |task|
        task.modified_by(you).save!
        def task.delay(duration = 2.hours)
          Task.delay(duration)
          self
        end
      end
    end


    # Tasks you should not see.
    create :title=>'You will not see this task since this task is reserved.', :status=>'reserved', :creator=>you, :potential_owners=>[]
    create :title=>'You will not see this task since you are not a stakeholder.', :potential_owners=>[]
    # Tasks in which we are:
    # - creator
    # - owner
    # - observer
    # - admin
    create :creator=>you
    create(:creator=>you).delay(25.minutes).modified_by(you).update_attributes :owner=>you
    create :observers=>you
    create :admins=>you
    # Tasks in which we are only or one of many potential owners.
    create :potential_owners=>you
    create(:potential_owners=>[you, other]).delay(45.minutes).update_attributes :owner=>other
    # High priority should show first.
    create :owner=>you, :priority=>Task::PRIORITIES.first
    # Over-due before due today before anything else.
    create :owner=>you, :due_on=>Time.today - 1.day
    create :owner=>you, :due_on=>Time.today
    create :owner=>you, :due_on=>Time.today + 1.day
    # Completed, cancelled, suspended
    create(:potential_owners=>[you, other]).delay(30.minutes).modified_by(other).update_attributes(:status=>'suspended')
    create(:owner=>you, :status=>'active').delay(2.hours).modified_by(you).update_attributes(:status=>'completed')
    create(:owner=>you, :status=>'active').delay(96.minutes).modified_by(other).update_attributes(:status=>'cancelled')
  end

end
