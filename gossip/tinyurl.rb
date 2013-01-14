require 'net/http'
require 'cgi'
require 'timeout'

module Gossip
  module Tinyurl

    # Base exception class
    class TinyurlException < Exception; end
    # Exception class
    class InvalidUrlException < TinyurlException; end

    @@lookup_tiny_urls = {}

    def self.shorten(url)
      @url = url
      if should_lookup_tiny_url?
        @@lookup_tiny_urls[url] = lookup_tiny_url(url)
      else
        @@lookup_tiny_urls[url] || url
      end
      @@lookup_tiny_urls[url]
    end

    private

    def self.endpoint_with(url)
      "#{endpoint}?format=simple&url=#{CGI.escape(url)}"
    end

    def self.endpoint
      "http://is.gd/create.php"
    end

    def self.environment
      ENV['RACK_ENV']
    end

    def self.cached?
      !@@lookup_tiny_urls[@url].nil?
    end

    # If we sohuld ask the API...
    def self.should_lookup_tiny_url?
      return false if cached?
      case environment
      when "production" then return true
      when "staging" then return true
      else return false
      end
      false
    end

    # Get a nice one from the API
    def self.lookup_tiny_url(url)
      begin
        timeout(5) do
          uri = URI.parse(endpoint_with(url))
          res = Net::HTTP.start(uri.host, uri.port) do |http|
            http.get("#{uri.path}?#{uri.query}")
          end
          if (200..299).include?(res.code.to_i)
            url = res.body if res
          elsif res.code.to_i == 500
            raise InvalidUrlException
          end
        end
      rescue Timeout::Error
      end
      url
    end
  end
end
