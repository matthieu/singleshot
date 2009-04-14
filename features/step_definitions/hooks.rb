# Singleshot  Copyright (C) 2008-2009  Intalio, Inc
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


require 'rack'


class RackApp
  def self.instance
    @instance ||= RackApp.new
  end

  def self.start
    unless @started
      Thread.new do
        Rack::Handler::WEBrick.run instance, :Port=>1234, :Logger=>WEBrick::Log.new(nil, WEBrick::Log::ERROR)
      end
      @started = true
    end
  end

  def initialize
    @resources = {}
  end

  attr_reader :resources

  def resource(url)
    @resources[url] ||= []
  end

  def call(env)
    resource(env['REQUEST_URI']) << { :method=>env['REQUEST_METHOD'], :enctype=>env['CONTENT_TYPE'] }
    [ '200', {}, 'OK' ]
  end
end


Given /^the resource (\S+)$/ do |url|
  RackApp.instance.resource url
  RackApp.start
end

Then /^the resource (\S+) receives (\S+) notification$/ do |url, method|
  RackApp.instance.resource(url).last.should include(:method=>method)
end
