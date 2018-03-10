# frozen_string_literal: true

module RailwayOperation
  # This is the value object that holds the information necessary to
  # run an operation
  class Operation
    extend Forwardable

    attr_reader :name
    attr_accessor :fails_step,
                  :step_exceptions,
                  :operation_surrounds,
                  :step_surrounds,
                  :track_alias,
                  :tracks

    def initialize(name)
      @name = underscore(name)

      @fails_step = TypedArray.new(
        ensure_type_is: Exception,
        error_message: 'Step failures must be an kind of Exception'
      )

      @operation_surrounds = Array.new
      @step_surrounds = EnsuredAccess.new({}) { StepsArray.new }

      @track_alias = {}
      @tracks = FilledMatrix.new(row_type: StepsArray)
    end

    def [](track_identifier, step_index = nil)
      tracks[
        track_index(track_identifier),
        step_index
      ]
    end

    def []=(track_identifier, step_index, step)
      tracks[
        track_index(track_identifier),
        step_index
      ] = step
    end

    def add_step(
      track_indentifier,
      method,
      success: nil,
      failure: nil,
      &block
    )
      self[track_indentifier, last_step_index + 1] = {
        method: block || method,
        success: success,
        failure: failure
      }
    end

    def alias_tracks(mapping = {})
      @track_alias.merge!(mapping)
    end

    def nest(operation)
      operation.tracks.each_with_index do |track, track_index|
        track.each do |s|
          tracks[track_index, last_step_index + 1] = s
        end
      end
    end

    def last_step_index
      tracks.max_column_index
    end

    def successor_track(track_identifier)
      track_index(track_identifier) + 1
    end

    def track_index(track_identifier)
      if track_identifier.is_a?(Numeric)
        track_identifier
      else
        @track_alias[track_identifier]
      end
    end

    private

    def underscore(string)
      string
        .to_s
        .gsub(/\s+/, '_')
        .downcase
        .to_sym
    end
  end
end
