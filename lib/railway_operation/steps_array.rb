# frozen_string_literal: true

module RailwayOperation
  # Ensures that the array containing surrounds are of valid type
  class StepsArray < TypedArray
    def initialize(*args, **options)
      types = [Symbol, Proc, String, Array]

      super(
        *args,
        ensure_type_is: types,
        error_message: 'Invalid operation surround declaration, must' \
          "be of type #{types}",
        **options
      )
    end
  end
end
