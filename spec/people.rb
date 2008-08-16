module SpecHelpers

  module People
    def self.included(base)
      base.after :each do
        Person.delete_all
      end
    end

    def person(identity)
      Person.identify(identity) rescue Person.create!(:email=>"#{identity}@apache.org", :password=>'secret')
    end

    def people(*identities)
      identities.map { |identity| person(identity) }
    end
  end

  # Authentication support for use with controllers.
  module Authentication

    # Authenticates as the specified person.
    #
    # You can use this with a block to authenticate only for the duration of a block:
    #   authenticate owner do
    #     ...
    #   end
    #
    # Without arguments, authenticates as 'person'.
    def authenticate(person = person('person'))
      previous, session[:person_id] = session[:person_id], person.id
      if block_given?
        begin
          yield
        ensure
          session[:person_id] = previous
        end
      end
    end

    # Returns the currently authenticated person.
    def authenticated
      Person.find(session[:person_id]) if session[:person_id] 
    end

    # Returns true if the previous request was authenticated and authorized.
    def authorized?
      !(response.redirected_to == session_url || response.code == '401')
    end

  end
end


Spec::Runner.configure do |config|
  config.include SpecHelpers::People
  config.include SpecHelpers::People
  config.include SpecHelpers::Authentication, :type=>:controller
end