module TaskHelper

  def quick_actions(task)
    [ task.admin?(authenticated) && button_to('Manage', edit_task_url(task), :method=>:get, :title=>'Manage this task'),
      task.can_claim?(authenticated) && button_to('Claim', task_url(task, 'task[owner]'=>authenticated.identity),
                                                                          :method=>:put, :title=>'Claim task')
    ].select { |action| action }.join(' ')
  end

  def task_vitals(task)
    vitals = ['Created ' + relative_date_abbr(task.created_at, :class=>'published')]
    vitals.first << ' by ' + link_to_person(task.creator, :creator) if task.creator
    vitals << (task.status == 'completed' ? "completed by " : "assigned to ") + link_to_person(task.owner, :owner) if task.owner
    vitals << "due #{relative_date_abbr(task.due_on)}" if task.due_on
    vitals.to_sentence
  end

  def task_frame(task)
    if task.form_perform_url
      task_uri = URI(task_perform_url(task))
      task_uri.user, task_uri.password = '_token', task.token_for(authenticated)
      uri = URI(task.owner?(authenticated) ? task.form_perform_url : (task.form_view_url || task.form_perform_url)) 
      uri.query = CGI.parse(uri.query || '').update('perform'=>task.owner?(authenticated), 'task_url'=>task_uri).to_query
      uri.to_s
      content_tag 'iframe', '', :id=>'task_frame', :src=>uri.to_s
    end
  end

end
