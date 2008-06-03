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
      vitals.first << ' by ' + link_to_person(task.creator, :rel=>:creator) if task.creator
      vitals << 'assigned to ' + link_to_person(task.owner, :rel=>:owner) if task.owner
      vitals << 'high priority' if task.high_priority?
      vitals << 'due ' + abbr_date(task.due_on, relative_date(task.due_on)) if task.due_on
      vitals.to_sentence
    when 'active'
    when 'suspended'
      return "Suspended"
    when 'completed'
      "Completed on #{task.updated_at.to_date.to_s(:long)} by #{link_to_person task.owner, :rel=>:owner}"
    when 'cancelled'
      "Cancelled on #{task.updated_at.to_date.to_s(:long)}"
    end
  end

  def task_frame(task, performing)
    state_uri = URI(task_perform_url(task))
    state_uri.user, state_uri.password = '_token', task.token_for(authenticated)
    params = { 'task_url'=>state_uri.to_s }
    if performing
      uri = URI(task.rendering.perform_url)
      params.update 'complete_url'=>complete_redirect_tasks_url if task.rendering.completing
    else
      uri = URI(task.rendering.details_url)
    end
    uri.query = CGI.parse(uri.query || '').update(params).to_query
    content_tag 'iframe', '', :id=>'task_frame', :src=>uri.to_s
  end

end
