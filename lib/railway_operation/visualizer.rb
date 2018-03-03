# frozen_string_literal: true
require 'graphviz'

module RailwayOperation
  class Visualizer
    extend Forwardable

    attr_reader :graph,
                :info,
                :operation

    def_delegators :graph,
                   :add_edges,
                   :add_graph,
                   :output

    def self.render(operation:, info: {})
      new(operation: operation, info: info).render
    end

    def initialize(operation:, info: {})
      @operation = operation
      @info = info
      @graph = GraphViz.new(:G, rankdir: 'LR')
    end

    def render
      matrix = graph_matrix
      join_track_nodes(matrix)
      output(png: 'hello_world.png')
    end

    def graph_matrix
      graph_matrix = []
      operation.tracks.each_with_index do |track, track_index|
        track_identifier = operation.track_alias.key(track_index) || track_index
        track_name = if track_identifier == track_index
                       track_identifier.to_s
                     else
                       "#{track_index}: #{track_identifier}"
                     end

        cluster = add_graph("cluster#{track_index}", label: track_name)
        track.each_with_index do |step, step_index|
          graph_matrix[track_index] ||= []
          graph_matrix[track_index][step_index] = if step
                                                    cluster.add_nodes(step[:method].to_s)
                                                  else
                                                    cluster.add_nodes(
                                                      step_index.to_s,
                                                      label: 'noop',
                                                      fontcolor: 'grey',
                                                      shape: 'none'
                                                    )
                                                  end
        end
      end

      graph_matrix
    end

    def join_track_nodes(graph_matrix)
      graph_matrix.each do |track|
        join_steps(track)
      end
    end

    def join_steps(steps)
      return unless steps.length >= 2
      n1, *rest = steps
      add_edges(n1, rest[0])
      join_steps(rest)
    end
  end
end
