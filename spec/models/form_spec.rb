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


require File.dirname(__FILE__) + '/helpers'


# == Schema Information
# Schema version: 20090402190432
#
# Table name: forms
#
#  id      :integer(4)      not null, primary key
#  task_id :integer(4)      not null
#  url     :string(255)
#  html    :text
describe Form do
  it { should belong_to(:task) }

  it { should have_attribute(:url) }
  it { should have_db_column(:url, :type=>:string) }

  it { should have_attribute(:html) }
  it { should have_db_column(:html, :type=>:text) }
end
