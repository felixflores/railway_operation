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

    attr_reader :name, :track_alias
    attr_accessor :operation_surrounds,
                  :step_surrounds

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

    def add_step(track_identifier, method = nil, &block)
      self[track_identifier, last_step_index + 1] = block || method
    end

    def stepper_function(fn = nil, &block)
      @stepper_function ||= fn || block
    end

    def tracks(*names)
      return @tracks if names.empty?
      @track_alias = [noop_track, *names]
    end

    def last_step_index
      tracks.max_column_index
    end

    def successor_track(track_id)
      next_index = track_index(track_id) + 1
      return if tracks.count <= next_index

      if track_id.is_a?(Numeric)
        next_index
      else
        track_identifier(next_index)
      end
    end

    def track_identifier(index)
      id = @track_alias[index] || index
      raise "Unable to determine track_identifier for `#{index}`" unless valid_track_id?(id)

      id
    end

    def track_index(track_identifier)
      index = @track_alias.index(track_identifier) || track_identifier
      raise "Invalid track `#{track_identifier}`, must be a positive integer" unless valid_index?(index)

      index
    end

    def noop_track
      NOOP_TRACK
    end

    private

    def valid_index?(index)
      index.is_a?(Numeric) && index.positive?
    end

    def valid_track_id?(id)
      valid_index?(id) || true
    end
  end
end
