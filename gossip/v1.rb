require 'sinatra'
require_relative 'tidbit'
require_relative 'sharing'
require_relative 'tinyurl'
require_relative 'email'

class GossipV1 < Sinatra::Base

  get '/share_by_email_or_sms/:id' do |id|
    tidbit = Gossip::Tidbit.find(id)
    recipients = [
      Gossip::Sharing.get_tokens(params[:emails]),
      Gossip::Sharing.get_tokens(params[:numbers])
    ].flatten.compact
    if params[:name] and params[:name].size > 40
      invalid_name = true
    else
      tinyurl = Gossip::Tinyurl.shorten(tidbit.permalink)
      host = URI.parse(tidbit.permalink)
      host = host.host if host.host
      msg = ""
      msg << "#{params[:name]} "
      msg << "wants you to see this! "
      msg << tidbit.permalink
      msg << " Sent from #{host}"
      params[:sms] = msg
    end
    params[:tidbit] = tidbit
    sent_to = Gossip::Sharing.send_to_recipients(params)
    sent_to ||= []

    unless invalid_name
      if recipients.size == sent_to.size
        {"sent_to" => sent_to}.to_json
      elsif sent_to.any?
        {"sent_to" => sent_to}.to_json
      else
        error = "Couldn't find any "
        error << "valid recipients "
        error << "who hadn't already "
        error << "received this tip."
        halt 400, error
      end
    else
      halt 400, "Invalid name"
    end
  end

  # ... ~300 more lines ...

end
