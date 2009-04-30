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


class TaskPresenter < BasePresenter

  def to_hash
    super do |hash|
      task.singular_roles.each do |role|
        if person = task.send(role)
          hash[role] = person.to_param
        end
      end
      task.plural_roles.each do |role|
        role = role.pluralize
        if people = task.send(role)
          hash[role] = people.map { |person| { role=>person.to_param } }
        end
      end
      hash['links'] = [ link_to('self', href) ]
      hash['actions'] = []
      hash['actions'] << action('claim', url_for(:id=>task, 'task[owner]'=>authenticated)) if authenticated.can_claim?(task)
      hash['actions'] << action('complete', url_for(:id=>task, 'task[status]'=>'completed')) if authenticated.can_complete?(task)
      hash['actions'] << action('cancel', url_for(:id=>task, 'task[status]'=>'cancelled')) if authenticated.can_cancel?(task)
    end
  end

end
