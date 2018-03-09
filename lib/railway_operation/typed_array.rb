# frozen_string_literal: true

module RailwayOperation
  # Ensure that only elements of specified type(s) are accepted in the array
  class TypedArray < Delegator
    class UnacceptableMember < StandardError; end
    DEFAULT_MESSAGE = 'invalid element type, unable to add element'

    def initialize(ensure_type_is:, error_message: DEFAULT_MESSAGE)
      @types = wrap(ensure_type_is)
      @error_message = error_message
      @arr = []
    end

    def __setobj__(arr)
      @arr = arr
    end

    def __getobj__
      @arr
    end

    def <<(element)
      if !check_class_type(element) && !check_instance_type(element)
        raise UnacceptableMember, @error_message
      end

      @arr << element
    end

    def check_class_type(element)
      return false unless element.is_a?(Class)
      @types.detect { |type| element <= type }
    end

    def check_instance_type(element)
      @types.detect { |type| element.is_a?(type) }
    end

    private

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
