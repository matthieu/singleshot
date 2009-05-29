class CreateNotification < ActiveRecord::Migration
  def self.up
    create_table :notifications do |t|
      t.string      :subject,      :null=>false, :limit=>200
      t.string      :body,         :limit=>4000
      t.string      :language,     :limit=>5
      t.belongs_to  :creator
      t.belongs_to  :task
      t.integer     :priority,     :null=>false, :limit=>1
      t.timestamps
    end

    create_table :notification_copies do |t|
      t.belongs_to :notification, :null=>false
      t.belongs_to :recipient,    :null=>false
      t.boolean    :marked_read,  :null=>false, :default=>false
    end
    add_index :notification_copies, [:notification_id, :recipient_id], :unique => true
    add_index :notification_copies, [:recipient_id, :marked_read]
  end

  def self.down
    drop_table :notifications
    drop_table :notification_copies
  end
end
