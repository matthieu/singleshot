class PopulateDatabase
    
  def populate
    puts "Populating database for #{you.identity}"
    Activity.delete_all
    Stakeholder.delete_all
    Task.delete_all
    Person.delete_all
    
    # Tasks you should not see.
    create :title=>'You will not see this task since this task is reserved.', :status=>'reserved', :creator=>you, :potential_owners=>[]
    create :title=>'You will not see this task since you are not a stakeholder.', :potential_owners=>[]
    # Tasks in which we are:
    # - creator
    # - owner
    # - observer
    # - admin
    create :creator=>you
    create(:creator=>you).delay(25.minutes).modify_by(you).update_attributes :owner=>you
    create :observers=>you
    create :admins=>you
    # Tasks in which we are only or one of many potential owners.
    create :potential_owners=>you
    create(:potential_owners=>[you, other]).delay(45.minutes).update_attributes :owner=>other
    # High priority should show first.
    create :owner=>you, :priority=>Task::PRIORITIES.first
    # Over-due before due today before anything else.
    create :owner=>you, :due_on=>Date.current - 1.day
    create :owner=>you, :due_on=>Date.current
    create :owner=>you, :due_on=>Date.current + 1.day
    # Completed, cancelled, suspended
    create(:potential_owners=>[you, other]).delay(30.minutes).modify_by(other).update_attributes(:status=>'suspended')
    create(:owner=>you, :status=>'active').delay(2.hours).modify_by(you).update_attributes(:status=>'completed')
    create(:owner=>you, :status=>'active').delay(96.minutes).modify_by(other).update_attributes(:status=>'cancelled')      
  end
    
protected
  
  def you
    @you ||= Person.identify(ENV['USER']) rescue begin
      puts "Creating an account for you:"
      puts "  Username: #{ENV['USER']}"
      puts "  Password: secret"
      Person.create!(:email=>"#{ENV['USER']}@apache.org", :password=>'secret')
    end
  end
  
  def other
    @other ||= Person.identify('anon') rescue Person.create(:email=>'anon@apache.org')
  end

  def create(attributes)
    PopulateDatabase.delay 
    defaults = { :title=>Faker::Lorem.sentence, :description=>Faker::Lorem.paragraphs(3).join("\n\n"),
                 :rendering=>{ :perform_url=>'http://localhost:3001/sandwich', :integrated_ui=>true },
                 :potential_owners=>[you, other] }
    task = Task.new(defaults.merge(attributes || {}))
    task.modify_by(you).save!
    def task.delay(duration = 2.hours)
      PopulateDatabase.delay(duration)
      self
    end
    task
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