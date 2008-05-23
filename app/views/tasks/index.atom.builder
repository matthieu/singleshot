atom_feed :root_url=>tasks_url do |feed|
  feed.title 'Singleshot: Tasks'
  feed.updated @tasks.map(&:updated_at).max

  for task in @tasks
    feed.entry task do |entry|
      entry.title task.title
      entry.content :type=>'html' do |content|
        content.text! sanitize(simple_format(task.description))
        content.text! "<p><em>#{task_vitals(task)}</em></p>"
        content.text! "<div>#{task_actions(task)}</div>"
      end
    end
  end
end
