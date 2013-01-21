require 'pony'

module Gossip
  class Email

    attr_reader :tidbit, :name_of_sender, :email
    def initialize(tidbit, name_of_sender, email)
      @tidbit = tidbit
      @name_of_sender = name_of_sender
      @email = email
    end

    def body
      <<-___
      #{tidbit.created_by.full_name} has created a tidbit of gossip about #{tidbit.recipient} on example.com.
      #{name_of_sender} would like you to take a look.

    Follow this link:
      #{tidbit.permalink}

    Join in the conversation by leaving a comment!
      ___
    end

    def dispatch
      options = {
        :to => email,
        :from => 'Village Gossip <gossip@example.com>',
        :subject => "#{name_of_sender} has sent you a tip!",
        :body => body,
        :text_part_charset => 'UTF-8'
      }
      Pony.mail options
    end

  end
end
