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

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with this
# work for additional information regarding copyright ownership.  The ASF
# licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.


class Webhook < ActiveRecord::Base

  def initialize(*args)
    super
    self[:http_method] ||= 'post'
    self.enctype ||= Mime::URL_ENCODED_FORM.to_s
  end

  belongs_to :task

  attr_accessible :event, :url, :method, :enctype
  validates_presence_of :event
  validates_presence_of :url
  validates_presence_of :http_method
  validates_presence_of :enctype
end
