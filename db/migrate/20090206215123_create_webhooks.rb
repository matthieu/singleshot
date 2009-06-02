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
    add_index :webhooks, [:task_id]
  end

  def self.down
    drop_table :webhooks
  end
end
