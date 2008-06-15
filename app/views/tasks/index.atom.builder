atom_feed :root_url=>@alternate[Mime::HTML] do |feed|
  feed.title 'Singleshot: Tasks'
  feed.updated @tasks.map(&:updated_at).max

  for task in @tasks
    feed.entry task do |entry|
      entry.title task.title
      entry.content :type=>'html' do |content|
        content.text! sanitize(simple_format(task.description))
        content.text! "<p><em>#{task_vitals(task)}</em></p>"
      end
      entry.author do |author|
        author.name task.creator.fullname if task.creator
      end
    end
  end
end
