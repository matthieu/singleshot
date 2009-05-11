class Notification < ActiveRecord::Migration
  def self.up
    create_table :notification_copies do |t|
      t.belongs_to :notification
      t.belongs_to :recipient
      t.boolean    :read,         :null=>false, :default=>false
    end
    add_index :notification_copies, [:notification_id, :recipient_id], :unique => true
    add_index :notification_copies, [:recipient_id, :read]
  end

  def self.down
    drop_table :notification_copies
  end
end
