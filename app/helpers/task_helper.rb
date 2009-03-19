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


module TaskHelper

  def quick_actions(task)
    [ authenticated.can_change?(task) && button_to('Manage', edit_task_url(task), :method=>:get, :title=>'Manage this task'),
      authenticated.can_claim?(task) && button_to('Claim', task_url(task, 'task[owner]'=>authenticated),
                                                                          :method=>:put, :title=>'Claim task')
    ].select { |action| action }.join(' ')
  end

  def task_vitals(task)
    case task.status
    when 'ready', 'active'
      vitals = [ 'Created ' + abbr_time(task.created_at, relative_time(task.created_at), :class=>'published') ]
      vitals.first << ' by ' + link_to_person(task.creator, :rel=>'creator') if task.creator
      vitals << 'assigned to ' + link_to_person(task.owner, :rel=>'owner') if task.owner
      vitals << 'high priority' if task.high_priority?
      vitals << 'due ' + abbr_date(task.due_on, relative_date(task.due_on)) if task.due_on
      vitals.to_sentence
    when 'active'
    when 'suspended'
      return "Suspended"
    when 'completed'
      "Completed on #{task.updated_at.to_date.to_s(:long)} by #{link_to_person task.owner, :rel=>'owner'}"
    when 'cancelled'
      "Cancelled on #{task.updated_at.to_date.to_s(:long)}"
    end
  end

  def task_actions(task)
    actions = []
    actions << button_to('Cancel', task_url(task, 'task[status]'=>'cancelled'), :method=>:put, :title=>'Cancel this task') if authenticated.can_cancel?(task)
    if authenticated.can_suspend?(task)
      actions << button_to('Suspend', task_url(task, 'task[status]'=>'suspended'), :method=>:put, :title=>'Suspend this task', :disabled=>task.suspended?)
      actions << button_to('Resume', task_url(task, 'task[status]'=>'active'), :method=>:put, :title=>'Resume this task', :disabled=>!task.suspended?)
    end
    if authenticated.can_delegate?(task)
      others = task.potential_owners - [@task.owner]
      unless others.empty?
        actions << form_tag(task_url(task), :method=>:put, :class=>'button-to') + 
          '<select name="task[owner]"><option disabled>Select owner ...</option>' +
          options_for_select(others.map { |person| [person.fullname, person.to_param] }.sort) +
          '<option value="">Anyone</option></select><input type="submit" value="Delegate"></form>'
      end
    end
    actions.join
  end

  def task_for_person_url(task, person)
    uri = URI(super(task, person))
    uri.user, uri.password = '_token', task.token_for(person)
    uri.to_s
  end

  def link_to_task(task)
    link_to task.title, task_url(task)
  end

  #def task_url(task, *args)
  #  task.cancelled? ? cancelled_task_url(task, *args) : super
  #end

end
