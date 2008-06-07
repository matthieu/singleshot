class Stakeholders < ActiveRecord::Migration
  def self.up
    create_table :stakeholders do |t|
      t.integer :task_id,    :null=>false
      t.integer :person_id,  :null=>false
      t.string  :role,       :null=>false
      t.timestamps
    end
    add_index :stakeholders, [:task_id, :person_id, :role], :unique=>true
    add_index :stakeholders, [:task_id, :role]
    add_index :stakeholders, [:person_id, :role]
  end

  def self.down
    drop_table :stakeholders
  end
end
