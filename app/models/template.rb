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

  def initialize(*args, &block)
    super
    self[:status] ||= 'enabled'
  end


  # -- Stakeholders & Access control --

  # These stakeholders are used when transforming template to task.
  stakeholders 'creator', 'supervisors', 'potential_owners', 'excluded_owners', 'observers'
  attr_readonly 'creator'

  def can_update?(person) # Test is person can update template.
    supervisor?(person)
  end

  def can_destroy?(person) # Test is person can destroy template.
    supervisor?(person)
  end
  
  before_create do |template|
    template.supervisors = [template.creator] if template.supervisors.empty?
  end


  # Allowed statuses:
  # - enabled   -- Template can be used to create new tasks (default).
  # - disabled  -- Template cannot be used to create new tasks.
  statuses 'enabled', 'disabled'
  
  default_scope :order=>'title ASC'
  # Scope templates that should be listed for a person (the potential owner).
  named_scope :listed_for, lambda { |person| {
    :joins=>'JOIN stakeholders AS involved ON involved.task_id=tasks.id',
    :conditions=>["involved.person_id = ? AND involved.role = 'potential_owner' AND status = 'enabled'", person] } }
  # Scope templates that should be visible to a person (anyone but potential owner).
  named_scope :accessible_to, lambda { |person| {
    :joins=>'JOIN stakeholders AS involved ON involved.task_id=tasks.id',
    :conditions=>["involved.person_id = ? AND involved.role != 'excluded_owner'", person] } }


  # -- Activity log --

  after_create do |template|
    creator = template.creator || template.modified_by
    template.log! creator, 'template.created' if creator
  end

  before_update do |template|
    if template.modified_by
      changed = template.changed
      if changed.delete('status')
        case template.status
        when 'enabled'
          template.log! template.modified_by, 'template.enabled'
        when 'disabled'
          template.log! template.modified_by, 'template.disabled' 
        end
      end
      template.log! template.modified_by, 'template.modified'  unless changed.empty?
    end
  end

  before_destroy do |template|
    template.log! template.modified_by, 'template.deleted' if template.modified_by
  end


  # -- Template => Task --

  def to_task
    modified_by.tasks.new do |task|
      # We need this because stakeholders are not retrieved if we just used task.attributes = template.attributes
      Template.attr_accessible.each do |attr|
        task.send "#{attr}=", send(attr)
      end
      task.form = form.clone if form
      task.owner = task.creator = modified_by
    end
  end

end
