class CreateActivities < ActiveRecord::Migration
  def self.up
    create_table  'activities' do |t|
      t.belongs_to  'person'
      t.belongs_to  'task',       :null=>false
      t.string      'action',     :null=>false
      t.datetime    'created_at', :null=>false
    end
  end

  def self.down
    drop_table 'activities'
  end
end
