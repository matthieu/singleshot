class CreateStakeholders < ActiveRecord::Migration
  def self.up
    create_table 'stakeholders' do |t|
      t.belongs_to 'task'
      t.belongs_to 'person'
      t.string    'role',       :null=>false
      t.datetime  'created_at', :null=>false
    end
  end

  def self.down
    drop_table 'stakeholders'
  end
end
