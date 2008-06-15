atom_feed :root_url=>activity_url do |feed|
  feed.title @title
  feed.subtitle @subtitle
  feed.updated @activities.first.created_at unless @activities.empty?

  for activity in @activities
    person, task = activity.person, activity.task
    feed.entry activity, :url=>task_url(task) do |entry|
      entry.title activity_to_text(activity)
      entry.content :type=>'html' do |content|
        content.text! "<p>#{activity_to_html(activity)}</p>"
        content.text!  truncate(strip_tags(task.description), 250)
      end
      entry.author do |author|
        author.name activity.person.fullname if activity.person
      end
    end
  end
end
