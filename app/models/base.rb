class Base < ActiveRecord::Base

  def initialize(*args, &block)
    super
    self[:priority] ||= DEFAULT_PRIORITY
  end

  set_table_name 'tasks'

  # -- Descriptive --
  # title, description, language

  attr_accessible :title, :description, :language
  validates_presence_of :title  # Title is required, description and language are optional

  # -- Priority --
  PRIORITY = 1..3 # Priority ranges from 1 to 3, 1 is the highest priority.
  DEFAULT_PRIORITY = 2 # Default priority is 2.

  attr_accessible :priority
  validates_inclusion_of :priority, :in=>PRIORITY
  

  # -- Data and meta-data --

  serialize :data
  attr_accessible :data

  def data #:nodoc:
    write_attribute(:data, Hash.new) if read_attribute(:data).blank?
    read_attribute(:data) || write_attribute(:data, Hash.new)
  end
  
  validate { |task| task.errors.add :data, "Must be a hash" unless Hash === task.data }


  # -- Presentation --

  has_one :form, :dependent=>:delete, :foreign_key=>'task_id'
  attr_accessible :form

  def form_with_hash_typecase=(form) #:nodoc:
    self.build_form form
  end
  alias_method_chain :form=, :hash_typecase


  # -- Webhooks --
 
  has_many :webhooks, :dependent=>:delete_all, :foreign_key=>'task_id'
  attr_accessible :webhooks

  def webhooks_with_hash_mapping=(hooks) #:nodoc:
    self.webhooks_without_hash_mapping = hooks.map { |hook| Webhook === hook ? hook : Webhook.new(hook) }
  end
  alias_method_chain :webhooks=, :hash_mapping


  def template?
    false
  end

end
