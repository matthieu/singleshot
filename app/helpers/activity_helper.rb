module ActivityHelper

  EXPANDED_ACTIVITY_NAMES = { 'owner'=>'is owner of' }

  def activity_as_text(person, activities, task)
    sentence = activities.map { |activity| EXPANDED_ACTIVITY_NAMES[activity.name] || activity.name }.to_sentence
    person ? "#{person.fullname} #{sentence} #{task.title}" : "#{sentence.capitalize} #{task.title}"
  end

  def activity_as_html(person, activities, task, options = {})
    sentence = activities.map { |activity| EXPANDED_ACTIVITY_NAMES[activity.name] || activity.name }.to_sentence
    title = link_to(task.title, task_url(task), options[:task])
    person ? "#{link_to_person person, :rel=>options[:person]} #{sentence} #{title}" : "#{sentence.capitalize} #{title}"
  end

end
