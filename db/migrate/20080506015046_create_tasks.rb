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


class CreateTasks < ActiveRecord::Migration
  def self.up
    create_table 'tasks' do |t|
      t.string      'title',        :null=>false
      t.string      'description',  :null=>false
      t.integer     'priority',     :null=>false, :limit=>1
      t.date        'due_on',       :null=>true
      t.date        'start_by',     :null=>true
      t.string      'status',       :null=>false
      t.string      'perform_url'
      t.string      'details_url'
      t.string      'instructions'
      t.boolean     'integrated_ui'
      t.string      'outcome_url',  :null=>true
      t.string      'outcome_type', :null=>true
      t.string      'access_key',   :null=>true, :limit=>32
      t.text        'data',         :null=>false
      t.belongs_to  'context',      :null=>false
      t.integer     'version',      :null=>false, :default=>0
      t.timestamps
    end
  end

  def self.down
    drop_table 'tasks'
  end
end
