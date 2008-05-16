module ActionController
  # TestResponse for functional, CgiResponse for integration.
  class AbstractResponse
    StatusCodes::SYMBOL_TO_STATUS_CODE.each do |symbol, code|
      unless instance_methods.include?("#{symbol}?")
        define_method("#{symbol}?") { self.code == code.to_s }
      end
    end
  end
end
