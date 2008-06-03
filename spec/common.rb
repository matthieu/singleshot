module Specs

  module Authentication

    def self.included(base)
      base.after :all do
        Person.delete_all
      end
    end

    def person(identity)
      @_people ||= {}
      @_people[identity.to_s] ||= Person.identify(identity) ||
        Person.create(:email=>"#{identity}@apache.org", :password=>'secret')
    end

    def people(*identities)
      identities.map { |identity| person(identity) }
    end

    def su
      @_su ||= Person.create(:email=>'super@apache.org', :admin=>true)
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

  end

  module Tasks

    def self.included(base)
      base.after :all do
        Activity.delete_all
        Stakeholder.delete_all
        Task.delete_all
      end
      base.send :include, Authentication
    end

    def default_task(with = {})
      { :title=>'Test this',
        :outcome_url=>'http://test.host/outcome' }.merge(with)
    end

    def task_with_status(status, attributes = nil)
      attributes ||= {}
      attributes = attributes.reverse_merge(:admins=>person('admin'))
      task = case status
      when 'active'
        Task.create!(default_task.merge(attributes).merge(:status=>'active', :owner=>person('owner')))
      when 'completed' # Start as active, modified by owner.
        active = task_with_status('active', attributes)
        active.modify_by(person('owner')).update_attributes! :status=>'completed'
        active
      when 'cancelled', 'suspended' # Start as active, modified by admin.
        active = task_with_status('active', attributes)
        active.modify_by(person('admin')).update_attributes! :status=>status
        active
      else
        Task.create!(default_task.merge(attributes).merge(:status=>status))
      end

      def task.transition_to(status, attributes = nil)
        attributes ||= {}
        modify_by(attributes.delete(:modified_by) || Person.identify('admin')).update_attributes attributes.merge(:status=>status)
        self
      end
      def task.can_transition?(status, attributes = nil)
        transition_to(status, attributes).errors_on(:status).empty?
      end
      task
    end

  end

end
