# frozen_string_literal: true

module RailwayOperation
  # This class is responsible for calculating the vector of the next step
  # during an operation execution
  class Stepper
    module Argument
      DEFAULT = ->(execution:, **) { execution.last[:argument] }
      INITIAL = ->(execution:, **) { execution.first[:argument] }
      PREVIOUS = ->(execution:, **) { execution[-2][:argument] }
    end

    module TrackIdentifier
      DEFAULT = ->(execution:, **) { execution.last.track_identifier }
      INITIAL = ->(operation:, **) { operation.initial_track }
      NOOP = ->(operation:, **) { operation.noop_track }
    end

    module StepIndex
      DEFAULT = ->(execution:, **) { execution.last.step_index + 1 }
      INITIAL = ->(_) { 0 }
      CURRENT = ->(execution:, **) { execution.last.step_index }
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

    def self.step(*args, &block)
      new.step(*args, &block)
    end

    def step(stepper_function, info, &step_executor)
      stepper_function.call(self, info, &step_executor)
      self
    end

    # Manipulators

    def continue
      vector
    end

    def switch_to(specified_track)
      vector[:track_identifier] = lambda do |execution:, operation:, **|
        begin
          track = case specified_track
                  when Proc
                    specified_track.call(operation, execution.last.track_identifier)
                  else
                    specified_track
                  end

          operation.track_index(track) # ensures that track index is found in the operation
          track
        rescue Operation::NonExistentTrack
          raise "Invalid stepper_function specification for '#{operation.name}'"\
            "operation: invalid `switch_to(#{track})`"
        end
      end
    end

    def retry_step
      vector.merge!(
        argument: Argument::PREVIOUS,
        track_identifier: TrackIdentifier::DEFAULT
      )

      self
    end

    def restart_operation
      vector.merge!(
        argument: Argument::INITIAL,
        track_identifier: TrackIdentifier::INITIAL
      )

      self
    end

    def halt_operation
      vector.merge!(
        argument: Argument::DEFAULT,
        track_identifier: TrackIdentifier::NOOP
      )

      self
    end

    def fail_operation
      vector.merge!(
        argument: Argument::INITIAL,
        track_identifier: TrackIdentifier::NOOP
      )

      self
    end

    def successor_track
      lambda do |operation, current_track|
        operation.successor_track(current_track)
      end
    end

    def raise_error(e, info)
      info.execution.last_step[:succeeded] = false
      step_index = info.execution.length - 1
      track_identifier = info.execution.last_step[:track_identifier]

      message = "The operation was aborted because `#{e.class}' "\
        "was raised on track #{track_identifier}, step #{step_index} of the operation."\
        "\n\n#{info.display}\n\n"

      raise e, message, e.backtrace
    end
  end
end
