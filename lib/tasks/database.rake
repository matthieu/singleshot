require 'annotate_models/tasks'

namespace 'db' do

  desc 'Rebuild the database by running all migrations again'
  task 'rebuild'=>['environment', 'drop', 'create', 'migrate', 'test:clone', 'annotate_models']

end
