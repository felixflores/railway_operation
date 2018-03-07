# frozen_string_literal: true

module RailwayOperation
  class EnsuredHash
    def initialize(&block)
      @default = block
      @value = Hash.new
    end

    def [](key)
      @value[key] ||= @default.call
      @value[key]
    end

    def respond_to_missing?(method, _include_private = false)
      @value.respond_to?(method)
    end

    def method_missing(method, *args)
      if respond_to_missing?(method)
        @value.send(method, *args)
      else
        super
      end
    end
  end

  class Operation
    extend Forwardable

    attr_accessor :name,
                  :fails_step,
                  :step_exceptions,
                  :operation_surrounds,
                  :step_surrounds,
                  :track_alias,
                  :tracks

    def initialize(name)
      @fails_step = []
      @name = name.to_sym
      @operation_surrounds = []
      @step_surrounds = EnsuredHash.new { [] }
      @track_alias = {}
      @tracks = FilledMatrix.new
    end

    def [](track_identifier, step_index)
      tracks[
        track_alias[track_identifier] || track_identifier,
        step_index
      ]
    end

    def []=(track_identifier, step_index, step)
      tracks[
        track_alias[track_identifier] || track_identifier,
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
  end
end
