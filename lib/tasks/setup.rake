require 'rails_generator/secret_key_generator'

task 'secret.key' do |task|
  secret = Rails::SecretKeyGenerator.new(ENV['ID']).generate_secret
  File.open task.name, 'w' do |file|
    file.write secret
  end
  puts "Generated new secret in #{task.name}"
end

desc 'Run this task first to setup your test/development environment'
task 'setup'=>['gems:install', 'plugins:install', 'secret.key', 'db:create', 'db:test:clone', 'db:populate']

namespace 'plugins' do
  task 'install' do
    rb_bin = File.join(Config::CONFIG['bindir'], Config::CONFIG['ruby_install_name'])
    puts "Installing rspec plugin from Github"
    system 'rb_bin', 'script/plugin', 'git://github.com/dchelimsky/rspec.git'
    system 'rb_bin', 'script/plugin', 'git://github.com/dchelimsky/rspec-rails.git'  
  end
  
  task 'list' do
    plugins = Dir["#{Rails.root}/vendor/plugins/*"].map { |path| Rails::Plugin.new(path) }
    plugins.each do |plugin|
      puts "Plugin: #{plugin.name}\n(#{plugin.directory})"
      width = plugin.about.keys.map(&:size).max
      plugin.about.each do |key, value|
        puts "  %#{width}s: %s" % [key, value]
      end
      puts
    end
  end
end
