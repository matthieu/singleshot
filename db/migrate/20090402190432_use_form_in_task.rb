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


class UseFormInTask < ActiveRecord::Migration
  def self.up
    create_table :forms do |t|
      t.belongs_to  :task,        :null => false
      t.string      :url
      t.text        :html
    end

    change_table :tasks do |t|
      # New way of using forms from task does not require these fields.
      t.remove :perform_integrated
      t.remove :view_integrated
      t.remove :perform_url
      t.remove :view_url
    end
  end

  def self.down
    drop_table :forms
  end
end
