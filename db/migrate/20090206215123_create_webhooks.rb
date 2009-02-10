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


class CreateWebhooks < ActiveRecord::Migration
  def self.up
    create_table :webhooks do |t|
      t.belongs_to :task,         :null=>false
      t.string     :event,        :null=>false
      t.string     :url,          :null=>false
      t.string     :http_method,  :null=>false
      t.string     :enctype,      :null=>false
      t.string     :hmac_key
    end

    add_index :webhooks, [:task_id], :unique => true
  end

  def self.down
    drop_table :webhooks
  end
end
