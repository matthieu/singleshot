class Activities < ActiveRecord::Migration
  def self.up
    create_table  'activities' do |t|
      t.integer   'person_id',  :null=>false
      t.integer   'task_id',    :null=>false
      t.string    'action',     :null=>false
      t.datetime  'created_at', :null=>false
    end
  end

  def self.down
    drop_table 'activities'
  end
end
