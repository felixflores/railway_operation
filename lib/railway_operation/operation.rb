# frozen_string_literal: true

module RailwayOperation
  # This is the value object that holds the information necessary to
  # run an operation
  class Operation
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
      success: nil,
      failure: nil,
      &block
    )
      self[track_identifier, last_step_index + 1] = {
        method: block || method,
        success: success,
        failure: failure
      }
    end

    def stepper_function(fn = nil, &block)
      return @stepper_function if !fn && !block
      @stepper_function = block || fn
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

    def noop_track
      0
    end
  end
end
