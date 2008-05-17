desc 'Run development server on port 3000'
task 'run' do
  at_exit do
    puts 'Stopping Thin ...'
    system 'thin stop -s2'
  end
  puts 'Starting Thin ...'
  system "thin start -d -s2 -p #{ENV['PORT'] || '3000'}"
  system 'tail -f log/development.log'
end
