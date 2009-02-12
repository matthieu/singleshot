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


# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Being an open source project, we generate a new key on first use
# and store it in a separate file, not part of the source distribution.
secret = Rails.root + 'secret.key'
File.open secret, 'w' do |file|
  file.write ActiveSupport::SecureRandom.hex(64)
end unless File.exist?(secret)

ActionController::Base.session = {
  :key         => '_singleshot_session',
  :secret      => File.read(secret)
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
