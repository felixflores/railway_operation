# frozen_string_literal: true

module RailwayOperation
  # Ensure that only elements of specified type(s) are accepted in the array
  class TypedArray < Delegator
    class UnacceptableMember < StandardError; end
    DEFAULT_MESSAGE = 'invalid element type, unable to add element'

    def initialize(array = nil, ensure_type_is:, error_message: DEFAULT_MESSAGE)
      if array&.any? { |a| !element_acceptable?(a) }
        raise UnacceptableMember, @error_message
      end

      @types = wrap(ensure_type_is)
      @error_message = error_message
      @arr = array || []
    end

    def __setobj__(arr)
      @arr = arr
    end

    def __getobj__
      @arr
    end

    def <<(element)
      unless element_acceptable?(element)
        raise UnacceptableMember, @error_message
      end

      @arr << element
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
      if object.nil?
        []
      elsif object.respond_to?(:to_ary)
        object.to_ary || [object]
      else
        [object]
      end
    end
  end
end
