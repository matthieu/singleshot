desc 'Run development server on port 3000'
task 'run' do
  at_exit do
    task('stop').invoke
  end
  puts 'Starting Thin ...'
  system "thin start -s2 -p #{ENV['PORT'] || '3000'} -a localhost"
  system 'tail -f log/development.log'
end

desc 'Stop development server (if running)'
task 'stop' do
  puts 'Stopping Thin ...'
  system 'thin stop -s2'
end