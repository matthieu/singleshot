# == Schema Information
# Schema version: 20080621023051
#
# Table name: contexts
#
#  id          :integer         not null, primary key
#  title       :string(255)     not null
#  description :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

class Context < ActiveRecord::Base

  def initialize(attributes = {}) #:nodoc:
    super
    self.description ||= ''
  end

  has_many :tasks

end
