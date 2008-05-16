atom_feed :root_url=>activity_url do |feed|
  feed.title 'Singleshot: Activities'
  feed.updated @activities.first.created_at

  for activity in @activities
    feed.entry activity, :url=>task_url(activity.task) do |entry|
      entry.title "#{activity.person.fullname} #{activity.action} #{activity.task.title}"
      entry.content :type=>'html' do |content|
        content.text! "<p>#{link_to h(activity.person.fullname), activity.person.identity} #{activity.action} #{link_to h(activity.task.title), task_url(activity.task)}</p>"
        content.text! "<p>#{h(activity.task.description)}</p>"
      end
    end
  end
end
