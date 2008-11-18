namespace 'db' do

  desc 'Populate the database with mock values'
  task 'populate'=>['environment', 'create', 'migrate'] do
    require File.join(Rails.root, 'db/populate')
    PopulateDatabase.new.populate
  end

end
