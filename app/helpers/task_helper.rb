module TaskHelper

  def quick_actions(task)
    [ task.admin?(authenticated) && button_to('Manage', edit_task_url(task), :method=>:get, :title=>'Manage this task'),
      task.can_claim?(authenticated) && button_to('Claim', task_url(task, 'task[owner]'=>authenticated.identity),
                                                                          :method=>:put, :title=>'Claim task')
    ].select { |action| action }.join(' ')
  end

  def task_vitals(task)
    case task.status
    when 'ready', 'active'
      vitals = [ 'Created ' + abbr_time(task.created_at, relative_time(task.created_at), :class=>'published') ]
      vitals.first << ' by ' + link_to_person(task.creator, :creator) if task.creator
      vitals << 'assigned to ' + link_to_person(task.owner, :owner) if task.owner
      vitals << 'high priority' if task.high_priority?
      vitals << 'due ' + abbr_date(task.due_on, relative_date(task.due_on)) if task.due_on
      vitals.to_sentence
    when 'active'
    when 'suspended'
      return "Suspended"
    when 'completed'
      "Completed on #{task.updated_at.to_date.to_s(:long)} by #{link_to_person task.owner, :owner}"
    when 'cancelled'
      "Cancelled on #{task.updated_at.to_date.to_s(:long)}"
    end
  end

  def task_frame(task)
    if task.form_perform_url
      task_uri = URI(task_perform_url(task))
      task_uri.user, task_uri.password = '_token', task.token_for(authenticated)
      if task.can_complete?(authenticated)
        uri = URI(task.form_perform_url)
        uri.query = CGI.parse(uri.query || '').update('perform'=>'true', 'task_url'=>task_uri).to_query
      else
        uri = URI(task.form_view_url || task.form_perform_url)
        uri.query = CGI.parse(uri.query || '').update('task_url'=>task_uri).to_query
      end
      content_tag 'iframe', '', :id=>'task_frame', :src=>uri.to_s
    end
  end

end
