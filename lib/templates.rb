module Templates
end

require File.join(File.dirname(__FILE__), 'templates/ical')
ActionView::Template.register_template_handler(:ical, Templates::Ical)
