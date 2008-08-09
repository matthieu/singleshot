require 'rails_generator/secret_key_generator'

task 'secret.key' do |task|
  secret = Rails::SecretKeyGenerator.new(ENV['ID']).generate_secret
  File.open task.name, 'w' do |file|
    file.write secret
  end
  puts "Generated new secret in #{task.name}"
end

desc 'Run this task first to setup your test/development environment'
task 'setup'=>['secret.key', 'gems:install', 'db:create', 'db:test:clone', 'db:populate']
