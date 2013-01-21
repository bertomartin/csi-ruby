# Fake ActiveRecord
module ActiveRecord
  class Base; end
  class RecordNotFound < StandardError; end
end

class User < Struct.new(:full_name, :email)
end

module Gossip
  class Tidbit < ActiveRecord::Base

    attr_reader :id, :created_by, :recipient
    def initialize(id, options = {})
      @id = id
      @created_by = options[:created_by]
      @recipient = options[:recipient]
    end

    def self.find(id)
      id = id.to_i
      raise ActiveRecord::RecordNotFound unless TIDBITS.has_key?(id)

      # See the tests for the defined tidbits
      TIDBITS[id]
    end

    def permalink
      "http://example.com/ec#{id}"
    end

    # ~470 more lines of code
  end
end
