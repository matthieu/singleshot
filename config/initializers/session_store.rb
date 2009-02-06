# Be sure to restart your server when you modify this file.

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
