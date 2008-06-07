class Tasks < ActiveRecord::Migration
  def self.up
    create_table :tasks do |t|
      t.string    :title,        :null=>true
      t.integer   :priority,     :null=>true, :default=>1, :limit=>1
      t.date      :due_on,       :null=>true
      t.integer   :status,       :null=>false, :default=>0, :limit=>2
      t.string    :frame_url,    :null=>true
      t.string    :outcome_url,  :null=>true
      t.string    :outcome_type, :null=>true
      t.integer   :cancellation, :null=>true, :limit=>1
      t.string    :access_key,   :null=>false, :limit=>32
      t.text      :data,         :null=>false
      t.integer   :version,      :null=>false, :default=>0
      t.timestamps
    end
    add_index :tasks, [:status, :updated_at]
  end

  def self.down
    drop_table :tasks
  end
end
