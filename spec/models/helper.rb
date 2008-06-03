module Helper
  module Models

    def self.included(base)
      base.after :all do
        Activity.delete_all
        Stakeholder.delete_all
        Task.delete_all
        Person.delete_all
        @authenticated = nil
      end
    end

    def person(identity)
      Person.identify(identity) || Person.create(:email=>"#{identity}@apache.org", :password=>'secret')
    end

    def people(*identities)
      identities.map { |identity| person(identity) }
    end

    def su
      Person.identify('super') || Person.create(:email=>'super@apache.org', :admin=>true)
    end

    def authenticate(person)
      @authenticated = person
      session[:person_id] = person.id
      credentials = [person.identity, 'secret']
      request.headers['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(*credentials)
    end

    attr_reader :authenticated

    def all_roles
      singular = ['creator', 'owner'].inject({}) { |h, role| h.update(role=>person(role)) }
      ['potential_owners', 'observers', 'admins'].inject(singular) { |h, role|
        h.update(role.to_sym=>Array.new(3) { |i| person("#{role.singularize}#{i}") }) }
    end

    def defaults(attributes = {})
      { :title=>'Test this',
        :outcome_url=>'http://test.host/outcome' }.merge(attributes)
    end

    def task_with_status(status, attributes = nil)
      attributes ||= {}
      attributes = attributes.reverse_merge(:admins=>person('admin'))
      task = case status
      when 'active'
        Task.create!(defaults(attributes).merge(:status=>'active', :owner=>person('owner')))
      when 'completed' # Start as active, modified by owner.
        active = task_with_status('active', attributes)
        active.modify_by(person('owner')).update_attributes! :status=>'completed'
        active
      when 'cancelled', 'suspended' # Start as active, modified by admin.
        active = task_with_status('ready', attributes)
        active.modify_by(person('admin')).update_attributes! :status=>status
        active
      else
        Task.create!(defaults(attributes).merge(:status=>status))
      end

      def task.transition_to(status, attributes = nil)
        attributes ||= {}
        modify_by(attributes.delete(:modified_by) || Person.identify('admin')).update_attributes attributes.merge(:status=>status)
        self
      end
      def task.can_transition?(status, attributes = nil)
        transition_to(status, attributes).errors_on(:status).empty?
      rescue ActiveRecord::ReadOnlyRecord
        false
      end
      task
    end

  end

end


Spec::Runner.configure do |config|
  config.include Helper::Models, :type=>:model
end
