atom_feed :root_url=>tasks_url do |feed|
  feed.title 'Singleshot: Tasks'
  feed.updated @tasks.map(&:updated_at).max

  for task in @tasks
    feed.entry task do |entry|
      entry.title task.title
      entry.content :type=>'html' do |content|
        priority = "<span style='color:red'>✭</span> " if task.priority == Task::PRIORITIES.first
        content.text! "<p>#{priority}#{h(task.description)}</p>"
        content.text! "<p><em>#{task_vitals(task)}</em></p>"
        content.text! "<div>#{task_actions(task)}</div>"
      end
    end
  end
end
