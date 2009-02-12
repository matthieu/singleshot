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


class CreatePeople < ActiveRecord::Migration
  def self.up
    create_table :people do |t|
      t.string   :identity,                 :null => false
      t.string   :fullname,                 :null => false
      t.string   :email,                    :null => false
      t.string   :locale,     :limit => 5
      t.integer  :timezone,   :limit => 4
      t.string   :password,   :limit => 64
      t.string   :access_key, :limit => 32, :null => false
      t.timestamps
    end

    add_index :people, [:identity],   :unique => true
    add_index :people, [:access_key], :unique => true
    add_index :people, [:email],      :unique => true
    add_index :people, [:fullname]
  end

  def self.down
    drop_table :people
  end
end
