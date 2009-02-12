# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090206215123) do

  create_table "activities", :force => true do |t|
    t.integer  "person_id",  :null => false
    t.integer  "task_id",    :null => false
    t.string   "name",       :null => false
    t.datetime "created_at", :null => false
  end

  add_index "activities", ["person_id", "task_id", "name"], :name => "index_activities_on_person_id_and_task_id_and_name", :unique => true

  create_table "people", :force => true do |t|
    t.string   "identity",                 :null => false
    t.string   "fullname",                 :null => false
    t.string   "email",                    :null => false
    t.string   "locale",     :limit => 5
    t.integer  "timezone",   :limit => 4
    t.string   "password",   :limit => 64
    t.string   "access_key", :limit => 32, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "people", ["access_key"], :name => "index_people_on_access_key", :unique => true
  add_index "people", ["email"], :name => "index_people_on_email", :unique => true
  add_index "people", ["fullname"], :name => "index_people_on_fullname"
  add_index "people", ["identity"], :name => "index_people_on_identity", :unique => true

  create_table "stakeholders", :force => true do |t|
    t.integer  "person_id",  :null => false
    t.integer  "task_id",    :null => false
    t.string   "role",       :null => false
    t.datetime "created_at", :null => false
  end

  add_index "stakeholders", ["person_id", "task_id", "role"], :name => "index_stakeholders_on_person_id_and_task_id_and_role", :unique => true

  create_table "tasks", :force => true do |t|
    t.string   "status",                           :null => false
    t.string   "title",                            :null => false
    t.string   "description"
    t.string   "language",           :limit => 5
    t.integer  "priority",           :limit => 1,  :null => false
    t.date     "due_on"
    t.date     "start_on"
    t.string   "cancellation"
    t.boolean  "perform_integrated"
    t.boolean  "view_integrated"
    t.string   "perform_url"
    t.string   "view_url"
    t.text     "data",                             :null => false
    t.string   "hooks"
    t.string   "access_key",         :limit => 32, :null => false
    t.integer  "version",                          :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "webhooks", :force => true do |t|
    t.integer "task_id",     :null => false
    t.string  "event",       :null => false
    t.string  "url",         :null => false
    t.string  "http_method", :null => false
    t.string  "enctype",     :null => false
    t.string  "hmac_key"
  end

  add_index "webhooks", ["task_id"], :name => "index_webhooks_on_task_id", :unique => true

end
