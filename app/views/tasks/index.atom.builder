atom_feed :root_url=>@alternate[Mime::HTML] do |feed|
  feed.title 'Singleshot: Tasks'
  feed.updated @tasks.map(&:updated_at).max
  feed.generator 'Singleshot', :version=>Singleshot::VERSION
  feed.author do |author|
    author.name 'Singleshot'
  end

  for task in @tasks
    feed.entry task do |entry|
      entry.title task.title
      entry.content :type=>'html' do |content|
        content.text! sanitize(simple_format(task.description))
        content.text! "<p><em>#{task_vitals(task)}</em></p>"
      end
      if creator = task.creator
        entry.author do |author|
          author.name  creator.fullname
          author.url   creator.url if creator.url
          author.email creator.email if creator.email
        end
      end
    end
  end
end
