module ActionController::HttpAuthentication::Basic
  def encode_credentials(user_name, password)
    %{Basic #{Base64.encode64("#{user_name}:#{password}").gsub(/\n/,'')}}
  end
end
