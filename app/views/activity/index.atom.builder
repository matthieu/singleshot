atom_feed :root_url=>@root_url do |feed|
  feed.title "Singleshot: #{@title}"
  feed.subtitle @subtitle
  feed.updated @activities.first.created_at unless @activities.empty?
  feed.link :href=>@next, :rel=>'next', :type=>Mime::ATOM if @next
  feed.link :href=>@previous, :rel=>'previous', :type=>Mime::ATOM if @previous
  feed.generator 'Singleshot', :version=>Singleshot::VERSION

  grouped = @activities.group_by { |activity| [activity.task, activity.person, activity.created_at] }
  grouped.each do |(task, person, published), related|
    feed.entry related.first, :url=>task_url(task) do |entry|
      related = presenting(related)
      entry.title related.single_entry(:text)
      entry.content related.single_entry(:html), :type=>'html'
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
