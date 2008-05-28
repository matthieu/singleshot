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
        Stakeholder.delete_all
        Task.delete_all
      end
      base.send :include, Authentication
    end

    def default_task(with = {})
      { :title=>'Test this',
        :outcome_url=>'http://test.host/outcome' }.merge(with)
    end

  end

end
