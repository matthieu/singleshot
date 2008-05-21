class Tasks < ActiveRecord::Migration
  def self.up
    create_table :tasks do |t|
      t.string    :title,        :null=>false
      t.string    :description,  :null=>false
      t.integer   :priority,     :null=>false, :limit=>1
      t.date      :due_on,       :null=>true
      t.string    :state,        :null=>false
      t.string    :frame_url,    :null=>true
      t.string    :outcome_url,  :null=>true
      t.string    :outcome_type, :null=>true
      t.string    :access_key,   :null=>true, :limit=>32
      t.text      :data,         :null=>false
      t.integer   :version,      :null=>false, :default=>0
      t.timestamps
    end
    add_index :tasks, [:state, :updated_at]
  end

  def self.down
    drop_table :tasks
  end
end
