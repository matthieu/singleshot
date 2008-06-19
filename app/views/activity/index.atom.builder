atom_feed :root_url=>@alternate[Mime::HTML] do |feed|
  feed.title "Singleshot: #{@title}"
  feed.subtitle @subtitle
  feed.updated @activities.first.created_at unless @activities.empty?
  feed.link :href=>@alternate[Mime::ICS], :rel=>'alternate', :type=>Mime::ICS if @alternate[Mime::ICS]
  feed.generator 'Singleshot', :version=>Singleshot::VERSION

  for activity in @activities
    person, task = activity.person, activity.task
    feed.entry activity, :url=>task_url(task) do |entry|
      entry.title activity_to_text(activity)
      entry.content :type=>'html' do |content|
        content.text! activity_to_html(activity)
      end
      person = activity.person
      entry.author do |author|
        author.name  person ? person.fullname : 'Unknown'
        author.url   person.url if person && person.url
        author.email person.email if person && person.email
      end
      [Mime::JSON, Mime::XML, Mime::ICS].each do |mime|
        feed.link :href=>formatted_tasks_url(task, :format=>mime), :rel=>'related', :type=>mime
      end
    end
  end
end
