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


class Notification < Base

  def initialize(*args, &block)
    super
    self[:status] = 'sent'
  end

  # -- Stakeholders & Access control --

  # Optional creator and list of recipients.
  stakeholders 'creator', 'recipients'
  validates_length_of :recipients, :minimum=>1

  before_validation { |notification| notification.readonly! unless notification.new_record? }

  named_scope :received, { :conditions=>["stakeholders.role = 'recipient'"], :order=>'tasks.created_at DESC' }
end
