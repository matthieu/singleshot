path = "#{Rails.root}/app/presenters"
# That way we're able to use everything in app/presenters.
ActiveSupport::Dependencies.load_paths << path
unless File.exist?(path)
  puts "Creating #{path}"
  Dir.mkdir path
end

require 'presenter'
