require 'rails_generator/secret_key_generator'

desc 'Run this task first to setup your test/development environment'
task 'setup'=>['gems:install', 'db:create', 'db:test:clone', 'db:populate']
