Dir["#{Rails.root}/lib/locale/*.yml"].each do |path|
  I18n.load_translations path
end