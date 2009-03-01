atom_feed :root_url=>@root_url do |feed|
  feed.title "Singleshot: #{@title}"
  feed.subtitle @subtitle
  feed.updated @activities.first.created_at unless @activities.empty?
  feed.link :href=>@next, :rel=>'next', :type=>Mime::ATOM if @next
  feed.link :href=>@previous, :rel=>'previous', :type=>Mime::ATOM if @previous
  feed.generator 'Singleshot', :version=>Singleshot::VERSION

  @activities.each do |activity|
    feed.entry activity, :url=>task_url(activity.task, :format=>nil) do |entry|
      task, person = activity.task, activity.person
      entry.title t("activity.expanded.#{activity.name}", :person=>activity.person, :task=>activity.task)
      #entry.content related.single_entry(:html), :type=>'html'
      entry.author do |author|
        author.name  person ? person.fullname : 'Unknown'
        author.url   person.url if person && person.url
        author.email person.email if person && person.email
      end
      [Mime::JSON, Mime::XML, Mime::ICS].each do |mime|
        feed.link :href=>tasks_url(task, :format=>mime), :rel=>'related', :type=>mime
      end
    end
  end
end
