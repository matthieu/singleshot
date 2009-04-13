module NavigationHelpers
  def path_to(page_name)
    case page_name
    when /the homepage/i
      root_path
    when /the tasks list/i
      tasks_path
    when /activity page/i
      activity_path
    when /the task "(.*)"/i
      task_path(Task.find_by_title($1))
    when /the form for "(.*)"/i
      form_path(Task.find_by_title($1))
    when /the frame "(.*)"/i
     frame_id = $1
     frame = Webrat::XML.xpath_search(current_dom, ".//iframe|frame").find { |elem| Webrat::XML.attribute(elem, 'id') == frame_id }
     fail "Did not find frame/iframe with ID #{id}" unless frame
     Webrat::XML.attribute(frame, 'src')
    else
      raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
        "Now, go and add a mapping in features/support/paths.rb"
    end
  end
end

World do |world|
  world.extend NavigationHelpers
  world
end
