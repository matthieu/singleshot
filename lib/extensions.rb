require File.join(File.dirname(__FILE__), 'extensions/validators')
ActiveRecord::Base.class_eval do
  include ActiveRecord::Validators::Url
  include ActiveRecord::Validators::Email
end

require File.join(File.dirname(__FILE__), 'extensions/ical_template')
ActionView::Template.register_template_handler(:ical, ActionView::TemplateHandlers::ICalTemplate)
