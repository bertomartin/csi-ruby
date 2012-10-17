module Gossip
  class Tipster
    class UnacceptableName < StandardError; end
    class MissingEmail < StandardError; end

    attr_accessor :e_card, :failed_emails
    attr_reader :emails, :tipper
    def initialize(e_card, options = {})
      self.e_card = e_card
      self.tipper = options[:tipper]
      self.emails = options[:emails]
      self.failed_emails = []
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
  end
end
