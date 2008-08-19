begin
  require 'annotate_models/tasks'
  
  desc task('annotate_models').comment
  task 'db:annotate'=>'annotate_models'
rescue LoadError
end
