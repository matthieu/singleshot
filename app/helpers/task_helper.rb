module TaskHelper

  def task_actions(task)
    actions = []
    actions << button_to('Manage', edit_task_url(task), :method=>:get, :title=>'Edit task') if task.admin?(authenticated)
    actions << button_to('Cancel', task_url(task), :method=>:delete, :title=>'Cancel this task') if task.can_cancel?(authenticated)
    actions << button_to('Claim', task_url(task, 'task[owner]'=>authenticated.identity), :method=>:put,
                         :title=>'Claim task', :disabled=>!task.can_claim?(authenticated)) if task.active? || task.ready?
    actions.join(' ')
  end

  def task_vitals(task)
    vitals = ['Created ' + relative_date_abbr(task.created_at, :class=>'published')]
    vitals.first << ' by ' + link_to_person(task.creator) if task.creator
    vitals << (task.status == 'completed' ? "completed by " : "assigned to ") + link_to_person(task.owner) if task.owner
    vitals << "due on #{task.due_on.to_formatted_s(:long)}" if task.due_on
    vitals.to_sentence
  end


  def task_bar_vitals(task, person = authenticated)
    case task.status
    when :suspended
      vitals = 'suspended'
    when :cancelled
      vitals = "cancelled #{relative_date_with_abbr(task.updated_at)}"
    when :completed
      vitals = "completed #{relative_date_with_abbr(task.updated_at)} by #{link_to_person(task.owner)}"
    else
      vitals = []
      if creator = task.creator
        vitals << "created by #{link_to_person(task.creator)}" unless creator == person
      end
      if owner = task.owner
        vitals << (person == owner ? 'assigned to you' : 'assigned to ' + link_to_person(owner))
      end
      vitals << "due #{relative_date_with_abbr(task.due_on)}" if task.due_on
      priority = [nil, 'medium', 'high'][task.priority - 1]
      vitals << "#{priority} priority" if priority
    end
    Array(vitals).join(', ').gsub(/^\w/) { |w| w.upcase }
  end

  def task_iframe_url(task, person = authenticated)
    task_uri = URI(task_url(task))
    task_uri.user, task_uri.password = '_token', task.token_for(person)
    uri = URI(task.frame_url)
    uri.query = CGI.parse(uri.query || '').update('perform'=>task.owner?(person), 'task_url'=>task_uri).to_query
    uri.to_s
  end

end
