# Singleshot  Copyright (C) 2008-2009  Intalio, Inc
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


# == Schema Information
#
# Table name: notifications
#
#  id         :integer(4)      not null, primary key
#  subject    :string(200)     not null
#  body       :string(4000)
#  language   :string(5)
#  creator_id :integer(4)
#  task_id    :integer(4)
#  priority   :integer(1)      not null
#  created_at :datetime
#  updated_at :datetime
#
class Notification < ActiveRecord::Base

  def initialize(*args, &block)
    super
    self[:priority] ||= 2
  end

  default_scope :order=>'created_at DESC'

  # -- Descriptive --
  
  attr_accessible :subject, :body, :language, :priority, :task
  belongs_to :task
  validates_presence_of :subject 
  validates_inclusion_of :priority, :in=>1..3
  before_validation { |notification| notification.readonly! unless notification.new_record? }


  # -- Creator & recipients --

  belongs_to :creator, :class_name=>'Person'
  has_many :recipients, :through=>:copies
  attr_accessible :creator, :recipients
  validates_length_of :recipients, :minimum=>1

  # Returns true if notification read by this recipient.
  def read?(person)
    copy(person).try(:read?)
  end

  # Marks notification as read by this recipient.
  def read!(person)
    copy(person).read!
  end


  # -- Copies --

  has_many :copies, :dependent=>:delete_all, :uniq=>true
  def copy(person) #:nodoc
    copies.find(:first, :conditions=>['recipient_id=?', person])
  end

  class Copy < ActiveRecord::Base
    set_table_name :notification_copies
    belongs_to :notification
    belongs_to :recipient, :class_name=>'Person'
    attr_readonly :notification, :recipient

    # Make this copy as read. For example:
    #   notif.copy(authenticated).read!
    def read!
      update_attributes! :read=>true
    end

    named_scope :read, :conditions=>'notification_copies.read'
    named_scope :unread, :conditions=>'!notification_copies.read'
  end


  # -- E-mail --

  after_save do |notification|
    notification.recipients.each do |recipient|
      Mailer.deliver_notification notification, recipient
    end
  end
end
