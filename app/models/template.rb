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


class Template < Base
  attr_readonly :due_on, :start_on, :status

  def initialize(*args, &block)
    super
    self[:status] = 'template'
  end

  # These stakeholders are used when transforming template to task.
  stakeholders 'supervisors', 'potential_owners', 'excluded_owners', 'observers'

  validates_inclusion_of :status, :in=>'template' # Make sure we don't accidentally have a Task status.


  def template?
    true
  end
end
