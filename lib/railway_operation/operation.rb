# frozen_string_literal: true

module RailwayOperation
  class Operation
    attr_reader :name, :mapping, :tracks
    attr_accessor :surrounds

    def initialize(name)
      @surrounds = []
      @tracks = []
      @track_alias = {}
      @name = name
    end

    def track(
      identifier,
      method = nil,
      failure: nil,
      success: nil,
      &block
    )
      fetch_track(identifier)[next_step_index] = {
        method: method || block,
        success: track_alias(success),
        failure: track_alias(failure)
      }
    end

    def alias_tracks(mapping = {})
      @track_alias.merge!(mapping)
    end

    def track_alias(identifier)
      @track_alias[identifier] || identifier
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
