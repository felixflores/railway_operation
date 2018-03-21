# frozen_string_literal: true

module RailwayOperation
  # This is the value object that holds the information necessary to
  # run an operation
  class Operation
    class NonExistentTrack < StandardError; end
    extend Forwardable

    # This track index is reserved so that we have a track that does
    # not have any steps
    NOOP_TRACK = 0

    attr_reader :name
    attr_accessor :operation_surrounds,
                  :step_surrounds,
                  :track_alias,
                  :tracks

    def self.new(operation_or_name)
      return operation_or_name if operation_or_name.is_a?(Operation)
      super
    end

    def self.format_name(op_or_name)
      case op_or_name
      when Operation
        op_or_name.name
      when String, Symbol
        op_or_name.to_s.gsub(/\s+/, '_').downcase.to_sym
      end
    end

    def initialize(name)
      @name = self.class.format_name(name)
      @operation_surrounds = []
      @step_surrounds = Generic::EnsuredAccess.new({}) { StepsArray.new }
      @track_alias = {}
      @tracks = Generic::FilledMatrix.new(row_type: StepsArray)
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
      track_identifier,
      method,
      &block
    )
      raise 'Track index must be a possitive integer' unless track_index(track_identifier).positive?

      self[track_identifier, last_step_index + 1] = block || method
    end

    def stepper_function(fn = nil, &block)
      return @stepper_function if !fn && !block
      @stepper_function = block || fn
    end

    def alias_tracks(mapping = {})
      @track_alias.merge!(mapping)
    end

    def last_step_index
      tracks.max_column_index
    end

    def successor_track(track_identifier)
      index = track_index(track_identifier) + 1
      track_identifier(index)
    end

    def track_identifier(index)
      @track_alias.invert[index] || index
    end

    def track_index(track_identifier)
      @track_alias[track_identifier] || track_identifier
    end

    def noop_track
      NOOP_TRACK
    end
  end
end
