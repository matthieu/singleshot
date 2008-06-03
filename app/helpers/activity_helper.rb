module ActivityHelper

  def activity_to_text(activity)
    activity.person ? "#{activity.person.fullname} #{activity.action} #{activity.task.title}" :
      "#{activity.action.capitalize} #{activity.task.title}"
  end

  def activity_to_html(activity, options = {})
    title = link_to(h(activity.task.title), task_url(activity.task), options[:task])
    activity.person ? "#{link_to_person activity.person, options[:person]} #{activity.action} #{title}" :
      "#{activity.action.capitalize} #{title}"
  end

end
