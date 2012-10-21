require_relative './email'

module Gossip
  class Tipster
    class UnacceptableName < StandardError; end
    class MissingEmail < StandardError; end

    def self.cache_expiration
      60 * 60 # one hour
    end

    attr_accessor :e_card, :failed_emails, :dispatched_emails
    attr_reader :emails, :tipper
    def initialize(e_card, options = {})
      self.e_card = e_card
      self.tipper = options[:tipper]
      self.emails = options[:emails]
      self.failed_emails = []
      self.dispatched_emails = []
    end

    def tipper=(name)
      fail UnacceptableName.new if name.nil?

      name = name.squeeze(" ").strip
      fail UnacceptableName.new if name.empty?

      @tipper = name
    end

    def emails=(emails)
      fail MissingEmail.new if emails.nil?

      emails = emails.split(',').map(&:strip).uniq
      fail MissingEmail.new if emails.empty?

      @emails = emails
    end

    def tip!
      emails.each do |email|
        dispatch_to(email) unless tipped?(email)
      end
    end

    def tipped!(email)
      Gossip.cache.set cache_key(email), 'tipped', Tipster.cache_expiration
      dispatched_emails << email
    end

    def tipped?(email)
      Gossip.cache.get cache_key(email)
    end

    def cache_key(email)
      "tipped:#{email}|e-card:#{e_card.id}"
    end

    def dispatch_to(email)
      Gossip::Email.new(e_card, tipper, email).dispatch
    rescue => e
      failed_emails << email
    else
      tipped!(email)
    end
  end
end
