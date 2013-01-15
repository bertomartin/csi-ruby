# This service takes care of API calls
# that are related to sharing.
module Gossip
  module Sharing

    def self.cache_expiration
      60 * 60 # one hour
    end

    # Sends a params[:message] to a set of params[:email_recipients]
    # and params[:sms_recipients]
    #
    def self.send_to_recipients(params)
      if params[:message]
        params[:sms] = params[:sms].squeeze(" ").strip
      end
      if params[:name]
        params[:name] = params[:name].squeeze(" ").strip
      end
      return false if params[:name].nil?
      return false if params[:name].empty?
      return false if params[:name].size > 41
      sent_to = []
      [params[:emails], params[:numbers]].each do |r_group|
        recipients = self.get_tokens(r_group)
        recipients = recipients.uniq
        recipients.each do |r|
          timestamp_cache_key = "tiptime:#{r}-#{params[:e_card].id}"
          timestamp = Gossip.cache.get(timestamp_cache_key)
          if timestamp.nil? || (timestamp && timestamp < Time.now-cache_expiration)
            # Different validations before sent with proper method
            if r =~ /^([^@\s,]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
              sent_to << r if self.send_to_email(r, params)
            elsif r =~ /^\s*\+?[0-9[:space:]]+\s*$/
              sent_to << r if self.send_to_sms(r, params)
            end
            Gossip.cache.set(timestamp_cache_key, Time.now)
          end
        end
      end
      sent_to
    end

    # Extract tokens from comma separated list
    def self.get_tokens(str)
      return [] unless str
      tokens = []
      tokenbits = str.split(',')
      tokenbits.each { |t|
        tokens << t.strip.downcase unless (t.nil? || t.strip.blank?)
      }
      return tokens
    end

    private

    # Send email
    def self.send_to_email(address, params)
      e_card = params[:e_card]
      Gossip::Email.new(e_card, params[:name], address).dispatch if e_card.created_by.email
      true
    end

    # Exception class.
    class SharingException < Exception; end

    # Send sms
    def self.send_to_sms(number, params)
      # TODO: Send SMS here
      false
    end

  end
end

