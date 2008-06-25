module ActivityHelper

  HUMANIZED_ACTIONS = { 'owner'=>'is owner of' }

  def humanize_actions(activities)
    activities.map { |activity| HUMANIZED_ACTIONS[activity.action] || activity.action }.to_sentence
  end

  def activity_as_text(person, activities, task)
    actions = humanize_actions(activities)
    person ? "#{person.fullname} #{actions} #{task.title}" : "#{actions.capitalize} #{task.title}"
  end

  def activity_as_html(person, activities, task, options = {})
    actions = humanize_actions(activities)
    title = link_to(task.title, task_url(task), options[:task])
    person ? "#{link_to_person person, :rel=>options[:person]} #{actions} #{title}" : "#{actions.capitalize} #{title}"
  end

end
