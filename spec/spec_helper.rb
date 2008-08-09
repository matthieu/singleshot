# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec/rails'
require File.expand_path(File.dirname(__FILE__) + '/people')
require File.expand_path(File.dirname(__FILE__) + '/tasks')

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

Spec::Runner.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  # You can declare fixtures for each behaviour like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so here, like so ...
  #
  #   config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
end
