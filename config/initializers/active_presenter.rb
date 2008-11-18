class ActiveRecord::Base
  include ActionController::UrlWriter
  
  class << self
    def default_url_options #:nodoc
      Thread.current[:request_options] ||= {}
    end
  end
  
  # Returns GUID for current object.  A GUID is s URN that identifies the host, object
  # type and object identifier, for example, guid for a Task model could be urn:example.com/tasks/1.
  def guid
    @guid ||= "urn:#{self.class.default_url_options[:host]}/#{ActionController::RecordIdentifier.singular_class_name(self)}/#{id}"
  end

  # Return URL for current object using polymorphic routes.  For example, calling
  # href on Task model returns task_url(self), or http://example.com/tasks/1.
  def href
    @href ||= polymorphic_url(self)
  end
end


class ActionController::Base
  
  around_filter :set_active_record_host

private

  def set_active_record_host
    options = { :protocol=>request.protocol, :host=>request.host }
    options[:port] = request.port unless request.port == 80
    Thread.current[:request_options] = options
    yield
  ensure
    Thread.current[:request_options] = nil
  end

end