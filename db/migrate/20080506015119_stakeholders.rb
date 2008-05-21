class Stakeholders < ActiveRecord::Migration
  def self.up
    create_table 'stakeholders' do |t|
      t.integer   'task_id',    :null=>false
      t.integer   'person_id',  :null=>false
      t.string    'role',       :null=>false
      t.datetime  'created_at', :null=>false
    end
  end

  def self.down
    drop_table 'stakeholders'
  end
end
