class WebMessagesChannel < ApplicationCable::Channel


  def subscribed
    channel_name = Digest::MD5.hexdigest(current_user.login+current_user.session_r5)
    stream_from "web_messages_channel_t#{channel_name}"
  end

  # ....
end

# ...
  def send
    ActionCable.server.broadcast("web_messages_channel_t#{@chanel_name}", message) if current_user.devices.map(&:id).include?(message[key]['number'].to_i)
  end
# ...
