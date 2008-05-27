class CreatePeople < ActiveRecord::Migration
  def self.up
    create_table 'people' do |t|
      t.string  'identity',   :null=>false
      t.string  'fullname',   :null=>false
      t.string  'email',      :null=>false
      t.string  'language',   :null=>true,  :limit=>5
      t.integer 'timezone',   :null=>true,  :limit=>4
      t.string  'password',   :null=>true,  :limit=>64
      t.string  'access_key', :null=>false, :limit=>32
      t.timestamps
    end

    add_index 'people', 'identity',   :unique=>true
    add_index 'people', 'fullname'
    add_index 'people', 'email',      :unique=>true
    add_index 'people', 'access_key', :unique=>true 
  end

  def self.down
    drop_table 'people'
  end
end
