# frozen_string_literal: true

module RailwayOperation
  module Generic
    # Ensures that the default value is available for use
    # The problem with normal default values is that they are returned,
    # they are not part of the actually collection.
    #
    # hash = Hash.new { [] }
    # hash['a'] == []
    #
    # However, if you do the following
    # hash['a'] << 2
    # hash == {}
    # hash['a'] != 2
    #
    # With this you can:
    #
    # ensured_hash = EnsuredAccess({}) { [] }
    # ensured_hash['a'] << 2
    # ensured_hash == { 'a' => 2 }
    class EnsuredAccess < Delegator
      def initialize(obj, default = nil, &block)
        @obj = obj
        @default = default || block
      end

      def __setobj__(obj)
        @obj = obj
      end

      def __getobj__
        @obj
      end

      def [](key)
        @obj[key] ||= @default.respond_to?(:call) ? @default.call : @default
        @obj[key]
      end
    end
  end
end
