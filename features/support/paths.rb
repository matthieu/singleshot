def path_to(page_name)
  case page_name
  when /the home page/i;  root_path(:only_path=>false)
  when /the tasks list/i;  tasks_url(:only_path=>false)
  when /activity page/i; activity_path
  when /the task "(.*)"/i ; task_url(Task.find_by_title($1))
  # Add more page name => path mappings here
  else raise "Can't find mapping from \"#{page_name}\" to a path."
  end
end
