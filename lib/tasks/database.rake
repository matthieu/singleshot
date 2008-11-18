namespace 'db' do

  desc 'Populate the database with mock values'
  task 'populate'=>['environment', 'create', 'migrate'] do
    require File.join(Rails.root, 'db/populate')
    PopulateDatabase.new.populate
  end

  begin
    # Conditional, otherwise rake setup fails not finding annotate_models.
    require 'annotate_models/tasks'

    desc task('annotate_models').comment
    task 'annotate'=>'annotate_models'
  rescue LoadError
  end

end