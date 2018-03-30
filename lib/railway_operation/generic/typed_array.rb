# frozen_string_literal: true

module RailwayOperation
  module Generic
    # Ensure that only elements of specified type(s) are accepted in the array
    class TypedArray < Delegator
      class UnacceptableMember < StandardError; end
      DEFAULT_MESSAGE = ->(type) { "unacceptable element in array, all elements must be of type #{type}" }.freeze

      def initialize(array = [], ensure_type_is:, error_message: nil)
        raise(ArgumentError, 'must be initialized with an array') unless array.is_a?(Array)

        @types = wrap(ensure_type_is)
        @error_message = error_message || DEFAULT_MESSAGE.(ensure_type_is)
        __setobj__(array)
      end

      def __setobj__(arr)
        raise UnacceptableMember, @error_message unless array_acceptable?(arr)
        @arr = arr
      end

      def __getobj__
        @arr
      end

      def <<(element)
        raise UnacceptableMember, @error_message unless element_acceptable?(element)
        @arr << element
      end

      def array_acceptable?(arr)
        arr&.all? { |a| element_acceptable?(a) }
      end

      def element_acceptable?(element)
        class_acceptable?(element) || instance_acceptable?(element)
      end

      private

      def class_acceptable?(element)
        return false unless element.is_a?(Class)
        @types.detect { |type| element <= type }
      end

      def instance_acceptable?(element)
        @types.detect { |type| element.is_a?(type) }
      end

      # Taken from ActiveSupport Array.wrap https://apidock.com/rails/Array/wrap/class
      def wrap(object)
        if object.respond_to?(:to_ary)
          object.to_ary || [object]
        else
          [object]
        end
      end
    end
  end
end
