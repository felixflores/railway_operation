# frozen_string_literal: true

module RailwayOperation
  # This class is responsible for calculating the vector of the next step
  # during an operation execution
  class Stepper
    def self.step(*args, &block)
      new.step(*args, &block)
    end

    module Argument
      DEFAULT = ->(argument, **) { argument }
      FAIL_OPERATION = ->(_argument, execution:, **) { execution.first[:argument] }
    end

    module TrackIdentifier
      DEFAULT = ->(track_identifier, **) { track_identifier }
      NOOP = ->(_, operation:, **) { operation.noop_track }
    end

    module StepIndex
      DEFAULT = ->(step_index, **) { step_index + 1 }
    end

    def vector
      @vector ||= {
        argument: Argument::DEFAULT,
        step_index: StepIndex::DEFAULT,
        track_identifier: TrackIdentifier::DEFAULT
      }
    end

    def [](key)
      vector[key]
    end

    def step(stepper_function, info, &step_executor)
      stepper_function.call(self, info, &step_executor)
      self
    end

    def halt_operation
      vector.merge!(
        argument: Argument::DEFAULT,
        track_identifier: TrackIdentifier::NOOP
      )
    end

    def fail_operation
      vector.merge!(
        argument: Argument::FAIL_OPERATION,
        track_identifier: TrackIdentifier::NOOP
      )
    end

    def fail_step
      continue
    end

    def continue
      vector
    end

    def switch_to(specified_track)
      vector[:track_identifier] = lambda do |track_identifier, operation:, **info|
        begin
          track = case specified_track
                  when Proc
                    specified_track.call(operation, track_identifier)
                  else
                    specified_track
                  end

          operation.track_index(track) # ensures that track index is found in the operation
          TrackIdentifier::DEFAULT.(track, info.merge(operation: operation))
        rescue Operation::NonExistentTrack
          raise "Invalid stepper_function specification for '#{operation.name}'"\
            "operation: invalid `switch_to(#{track})`"
        end
      end
    end

    def successor_track
      lambda do |operation, track_identifier|
        operation.successor_track(track_identifier)
      end
    end

    def error_message(e, info)
      info.execution.last_step[:succeeded] = false
      step_index = info.execution.length - 1
      track_identifier = info.execution.last_step[:track_identifier]

      "The operation was aborted because `#{e.class}' "\
        "was raised on track #{track_identifier}, step #{step_index} of the operation."\
        "\n\n#{info.display}\n\n"
    end
  end
end
