module ActionController #:nodoc:
  module TestResponseBehavior #:nodoc:
    def client_error?
      (400..499).include?(response_code)
    end
  end
end
