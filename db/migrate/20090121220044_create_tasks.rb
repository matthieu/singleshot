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


class CreateTasks < ActiveRecord::Migration
  def self.up
    create_table :tasks do |t|
      t.string   :status,                     :null => false
      t.string   :title,                      :null => false
      t.string   :description
      t.string   :language,     :limit => 5
      t.integer  :priority,     :limit => 1,  :null => false
      t.date     :due_on
      t.date     :start_on
      t.string   :cancellation
      t.boolean  :perform_integrated
      t.boolean  :view_integrated
      t.string   :perform_url
      t.string   :view_url
      t.text     :data,                       :null => false
      t.string   :hooks
      t.string   :access_key,   :limit => 32, :null => false
      t.integer  :version,                    :null => false
      t.timestamps
    end

    create_table :stakeholders do |t|
      t.belongs_to  :person,      :null => false
      t.belongs_to  :task,        :null => false
      t.string      :role,        :null => false
      t.datetime    :created_at,  :null => false
    end
    add_index :stakeholders, [:person_id, :task_id, :role], :unique => true

    create_table :activities do |t|
      t.belongs_to  :person,      :null => false
      t.belongs_to  :task,        :null => false
      t.string      :name,        :null => false
      t.datetime    :created_at,  :null => false
    end
    add_index :activities, [:person_id, :task_id, :name], :unique => true
  end

  def self.down
    drop_table :activities
    drop_table :stakeholders
    drop_table :tasks
  end
end
