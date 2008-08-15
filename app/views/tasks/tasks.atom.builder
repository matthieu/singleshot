atom_feed :root_url=>@alternate[Mime::HTML] do |feed|
  feed.title "Singleshot: #{@title}"
  feed.subtitle @subtitle
  feed.updated @tasks.map(&:updated_at).max
  feed.link :href=>@next, :rel=>'next', :type=>Mime::ATOM if @next
  feed.link :href=>@previous, :rel=>'previous', :type=>Mime::ATOM if @previous
  feed.link :href=>@alternate[Mime::ICS], :rel=>'alternate', :type=>Mime::ICS if @alternate[Mime::ICS]
  feed.generator 'Singleshot', :version=>Singleshot::VERSION

  for task in @tasks
    feed.entry task do |entry|
      entry.title task.title
      entry.content :type=>'html' do |content|
        content.text! sanitize(simple_format(task.description))
        content.text! "<p><em>#{task_vitals(task)}</em></p>"
      end
      creator = task.creator
      entry.author do |author|
        author.name  creator ? creator.fullname : 'Unknown'
        author.url   creator.url if creator && creator.url
        author.email creator.email if creator && creator.email
      end
      # TODO: Should we add last person who modified the task as secondary/primary author?
      [Mime::JSON, Mime::XML, Mime::ICS].each do |mime|
        feed.link :href=>formatted_tasks_url(task, :format=>mime), :rel=>'alternate', :type=>mime
      end
    end
  end
end
