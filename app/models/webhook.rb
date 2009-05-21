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


# Applications can use webhooks to be notified when the task completes, gets cancelled,
# or other interesting events.
#
# == Schema Information
# Schema version: 20090206215123
#
# Table name: webhooks
#
#  id          :integer         not null, primary key
#  task_id     :integer         not null
#  event       :string(255)     not null
#  url         :string(255)     not null
#  http_method :string(255)     not null
#  enctype     :string(255)     not null
#  hmac_key    :string(255)
#
class Webhook < ActiveRecord::Base

  # Creates new webhook with the following attributes (and defaults):
  # - event     -- Event name (e.g. completed, cancelled)
  # - url       -- Webhook URL
  # - method    -- HTTP method to use (default is POST)
  # - enctype   -- Encoding type (default is application/x-www-form-urlencoded)
  # - hmac_key  -- Optional key for generating x-hmac header
  def initialize(*args)
    super
    self[:http_method] ||= 'post'
    self[:enctype] ||= Mime::URL_ENCODED_FORM.to_s
  end

  belongs_to :task
 
  attr_accessible :event, :url, :http_method, :enctype, :hmac_key
  validates_presence_of :event, :url, :http_method, :enctype
  validates_url :url, :allow_nil=>true

  require 'net/http'
  require 'uri'

  def send_notification
    uri = URI.parse(url)
    Net::HTTP.start(uri.host, uri.port) do |http|
      case enctype
      when Mime::XML
        http.post uri.path, TaskPresenter.new(nil, task).to_xml, 'Content-Type'=>Mime::XML
      when Mime::JSON
        http.post uri.path, TaskPresenter.new(nil, task).to_json, 'Content-Type'=>Mime::JSON
      else
        http.post uri.path, { 'id'=>task.id, 'url'=>task_url(task) }.to_query, 'Content-Type'=>Mime::URL_ENCODED_FORM
      end
    end 
  end

end
