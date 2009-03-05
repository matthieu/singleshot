ENV['RAILS_ENV'] ||= 'test'
require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")
require 'spec/rails'

# Object being presented.
class Foo
end

# Presenter for Foo.
class FooPresenter < Presenter::Base
end

# Test controller, using similar name so we can deduct presenter from controller.
class FooController < ApplicationController
end