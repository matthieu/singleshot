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
    self[:status] = 'enabled'
  end

  # These stakeholders are used when transforming template to task.
  stakeholders 'creator', 'supervisors', 'potential_owners', 'excluded_owners', 'observers'

  # Allowed statuses:
  # - enabled   -- Template can be used to create new tasks (default).
  # - disabled  -- Template cannot be used to create new tasks.
  statuses 'enabled', 'disabled'
  
  default_scope :order=>'title ASC'

  def can_update?(person) # Test is person can update template.
    supervisor?(person)
  end

  def can_destroy?(person) # Test is person can destroy template.
    supervisor?(person)
  end

  # Scope templates that should be listed for a person (the potential owner).
  named_scope :listed_for, lambda { |person| {
    :joins=>'JOIN stakeholders AS involved ON involved.task_id=tasks.id',
    :conditions=>["involved.person_id = ? AND involved.role = 'potential_owner' AND status = 'enabled'", person] } }
  # Scope templates that should be visible to a person (anyone but potential owner).
  named_scope :accessible_to, lambda { |person| {
    :joins=>'JOIN stakeholders AS involved ON involved.task_id=tasks.id',
    :conditions=>["involved.person_id = ? AND involved.role != 'excluded_owner'", person] } }

end
