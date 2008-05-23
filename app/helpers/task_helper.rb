module TaskHelper

  def task_actions(task)
    manage = task.admin?(authenticated)
    cancel = task.can_cancel?(authenticated)
    claim = task.can_claim?(authenticated)
    actions = [
      manage && button_to('Manage', edit_task_url(task), :method=>:get, :title=>'Managed this task', :disabled=>!manage),
      cancel && button_to('Cancel', task_url(task), :method=>:delete, :title=>'Cancel this task', :disabled=>!cancel),
      claim && button_to('Claim', task_owner_url(task, 'owner'=>authenticated.identity), :method=>:put, :title=>'Claim task', :disabled=>!claim),
    ].select { |action| action }.join(' ')
  end

  def task_vitals(task)
    vitals = ['Created ' + relative_date_abbr(task.created_at, :class=>'published')]
    vitals.first << ' by ' + link_to_person(task.creator, :creator) if task.creator
    vitals << (task.status == 'completed' ? "completed by " : "assigned to ") + link_to_person(task.owner, :owner) if task.owner
    vitals << "due #{relative_date_abbr(task.due_on)}" if task.due_on
    vitals.to_sentence
  end

  def task_iframe_url(task, person = authenticated)
    task_uri = URI(task_url(task))
    task_uri.user, task_uri.password = '_token', task.token_for(person)
    uri = URI(task.frame_url)
    uri.query = CGI.parse(uri.query || '').update('perform'=>task.owner?(person), 'task_url'=>task_uri).to_query
    uri.to_s
  end

end
