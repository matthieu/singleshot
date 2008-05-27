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
    def retract(*models)
      models = Task, Stakeholder, Activity if models.empty?
      models.each do |model|
        model.all.each do |record|
          change = ['created_at = ?', record.created_at - 2.hour]
          if record.respond_to?(:updated_at)
            change.first << ', updated_at = ?'
            change << record.updated_at - 2.hour
          end
          model.update_all change, :id=>record.id 
        end
      end
    end

    def create(attributes)
      retract 
      you = Person.find_by_identity(ENV['USER']) 
      defaults = { :title=>Faker::Lorem.sentence, :description=>Faker::Lorem.paragraphs(3).join("\n\n"),
                   :frame_url=>'http://localhost:3001/sandwich', :potential_owners=>[you, other] }
      Task.new(defaults.merge(attributes || {})).modified_by(you).save!
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
    create :creator=>you ; retract ; Task.last.modified_by(you).update_attributes :owner=>you
    create :observers=>you
    create :admins=>you
    # Tasks in which we are only or one of many potential owners.
    create :potential_owners=>you
    create :potential_owners=>[you, other] ; retract ; Task.last.update_attributes :owner=>other
    # High priority should show first.
    create :owner=>you, :priority=>Task::PRIORITIES.first
    # Over-due before due today before anything else.
    create :owner=>you, :due_on=>Time.today - 1.day
    create :owner=>you, :due_on=>Time.today
    create :owner=>you, :due_on=>Time.today + 1.day
  end

end
