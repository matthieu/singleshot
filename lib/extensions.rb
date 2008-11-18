require File.expand_path('extensions/validators', File.dirname(__FILE__))

ActiveRecord::Base.class_eval do
  include ActiveRecord::Validators::Url
  include ActiveRecord::Validators::Email
end

require File.expand_path('extensions/ical_template', File.dirname(__FILE__))
ActionView::Template.register_template_handler(:ical, ActionView::TemplateHandlers::ICalTemplate)
