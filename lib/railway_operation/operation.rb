# frozen_string_literal: true

module RailwayOperation
  class Operation
    extend Forwardable

    attr_accessor :name,
                  :fails_step,
                  :step_exceptions,
                  :surrounds,
                  :surrounds_step,
                  :track_alias,
                  :tracks

    def initialize(name)
      @fails_step = []
      @name = name
      @surrounds = []
      @surrounds_step = {}
      @track_alias = {}
      @tracks = FilledMatrix.new
    end

    def [](track_identifier, step_index)
      tracks[
        track_alias[track_identifier] || track_indentifier,
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
        method: method || block,
        success: success,
        failure: failure
      }
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
