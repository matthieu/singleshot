desc 'Run development server on port 3000'
task 'run' do
  at_exit do
    puts 'Stopping Thin ...'
    system 'thin stop'
  end
  puts 'Starting Thin ...'
  system 'thin', 'start', '-d', '-p', ENV['PORT'] || '3000'
  system 'tail -f log/development.log'
end
