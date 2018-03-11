# frozen_string_literal: true

module RailwayOperation
  # Ensures that the array containing surrounds are of valid type
  class ExceptionsArray < TypedArray
    def initialize(*args, **options)
      super(
        *args,
        ensure_type_is: Exception,
        error_message: 'Operation failure classes must be a kind of Exception',
        **options
      )
    end
  end
end
