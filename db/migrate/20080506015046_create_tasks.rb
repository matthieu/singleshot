class CreateTasks < ActiveRecord::Migration
  def self.up
    create_table 'tasks' do |t|
      t.string    'title',        :null=>false
      t.string    'description',  :null=>false
      t.integer   'priority',     :null=>false, :limit=>1
      t.date      'due_on',       :null=>true
      t.string    'status',       :null=>false
      t.string    'perform_url'
      t.string    'details_url'
      t.boolean   'form_completing'
      t.string    'outcome_url',  :null=>true
      t.string    'outcome_type', :null=>true
      t.string    'access_key',   :null=>true, :limit=>32
      t.text      'data',         :null=>false
      t.integer   'version',      :null=>false, :default=>0
      t.timestamps
    end
  end

  def self.down
    drop_table 'tasks'
  end
end
