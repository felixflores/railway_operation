# frozen_string_literal: true

module RailwayOperation
  class Operation
    attr_reader :name, :mapping, :tracks
    attr_accessor :surrounds, :step_surrounds, :track_alias

    def initialize(name)
      @surrounds = []
      @step_surrounds = []
      @tracks = []
      @track_alias = {}
      @fails_step = []
      @name = name
    end

    def add_step(
      track,
      method = nil,
      failure: nil,
      success: nil,
      &block
    )
      fetch_track(track)[next_step_index] = {
        method: method || block,
        success: track_index(success),
        failure: track_index(failure)
      }
    end

    def fails_step(*exceptions)
      @fails_step += exceptions
    end

    def surround_steps(on_track:, with:)
      @step_surrounds[track_index(on_track)] ||= []
      @step_surrounds[track_index(on_track)] << with
    end

    def nest(operation)
      operation.tracks.each_with_index do |t, track_index|
        t.each do |step_definition|
          add_step(
            track_index,
            step_definition[:method],
            success: step_definition[:success],
            failure: step_definition[:failure]
          )
        end
      end
    end

    def alias_tracks(mapping = {})
      @track_alias.merge!(mapping)
    end

    def track_index(identifier)
      if identifier.is_a?(Numeric)
        identifier
      else
        @track_alias[identifier]
      end
    end

    def fetch_track(identifier)
      index = identifier.is_a?(Numeric) ? identifier : alias_tracks[identifier]
      tracks[index] ||= []
      tracks[index]
    end

    def next_step_index
      (tracks.compact.max_by(&:length) || []).length
    end

    def last_step_index
      next_step_index - 1
    end
  end
end
