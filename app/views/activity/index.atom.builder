atom_feed :root_url=>@alternate[Mime::HTML] do |feed|
  feed.title "Singleshot: #{@title}"
  feed.subtitle @subtitle
  feed.updated @activities.first.created_at unless @activities.empty?
  feed.link :href=>@next, :rel=>'next', :type=>Mime::ATOM if @next
  feed.link :href=>@previous, :rel=>'previous', :type=>Mime::ATOM if @previous
  feed.link :href=>@alternate[Mime::ICS], :rel=>'alternate', :type=>Mime::ICS if @alternate[Mime::ICS]
  feed.generator 'Singleshot', :version=>Singleshot::VERSION

  for (task, person, published), related in @activities.group_by { |activity| [activity.task, activity.person, activity.created_at] }
    feed.entry related.first, :url=>task_url(task) do |entry|
      entry.title activity_as_text(person, related, task)
      entry.content :type=>'html' do |content|
        content.text! activity_as_html(person, related, task)
      end
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
