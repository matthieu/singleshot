# Maps a static name to a static route.
#
# This method is *not* designed to map from a dynamic name to a 
# dynamic route like <tt>post_comments_path(post)</tt>. For dynamic 
# routes like this you should *not* rely on #path_to, but write 
# your own step definitions instead. Example:
#
#   Given /I am on the comments page for the "(.+)" post/ |name|
#     post = Post.find_by_name(name)
#     visit post_comments_path(post)
#   end
#
module NavigationHelpers
  def path_to(page_name)
    case page_name
    when /the homepage/
      root_path
    when /the tasks list/
      tasks_path
    when /activity page/
      activity_path
    when /the task "(.*)"/
      task_path(Task.find_by_title($1))
    when /the form for "(.*)"/
      form_path(Task.find_by_title($1))
    when /the frame "(.*)"/
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

World(NavigationHelpers)
