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


class ActivityObserver < ActiveRecord::Observer
  observe :task

  def after_create(task)
    creator = task.creator
    task.modified_by ||= creator
    task.activities.create :name=>'created', :person=>creator  if creator
    task.activities.create :name=>'claimed', :person=>task.owner if task.owner
  end

  def before_update(task)
    past_owner, owner = task.changes['owner']
    if owner
      task.activities.create :name=>'delegated', :person=>task.modified_by  if task.modified_by && task.modified_by != owner
      task.activities.create :name=>'claimed', :person=>owner
    else
      task.activities.create :name=>'released', :person=>past_owner
    end

    if task.status_changed?
      case task.status
      when 'active', 'available'
        task.activities.create :name=>'resumed', :person=>task.modified_by if task.status_was == 'suspended' && task.modified_by
      when 'suspended'
        task.activities.create :name=>'suspended', :person=>task.modified_by if task.modified_by
      when 'completed'
        task.activities.create :name=>'completed', :person=>task.owner
      when 'cancelled'
        task.activities.create :name=>'cancelled', :person=>task.modified_by if task.modified_by
      end
    end
  
    changed = task.changed - ['status', 'owner', 'past_owners']
    task.activities.create :name=>'modified', :person=>task.modified_by unless changed.empty?
  end

end
