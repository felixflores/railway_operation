# frozen_string_literal: true

module RailwayOperation
  class Stepper
    def self.step(*args, &block)
      new.step(*args, &block)
    end

    module Argument
      DEFAULT = lambda do |_operation, argument:|
        argument[:after]
      end

      FAIL_STEP = lambda do |_operation, argument:|
        argument[:before]
      end

      FAIL_OPERATION = lambda do |_operation, argument:|
        argument[:original]
      end
    end

    module TrackIdentifier
      DEFAULT = lambda do |_operation, track_identifier|
        track_identifier
      end

      NOOP = lambda do |operation, _track_identifier|
        operation.noop_track
      end
    end

    module StepIndex
      DEFAULT = lambda do |_operation, step_index|
        step_index + 1
      end
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

    def step(stepper_function, &step_executor)
      stepper_function.call(self, &step_executor)
      self
    end

    def halt_operation
      vector.merge!(
        argument: Argument::FAIL_STEP,
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
      vector.merge!(
        argument: Argument::FAIL_OPERATION,
        track_identifier: TrackIdentifier::DEFAULT
      )
    end

    def continue
      vector.merge!(
        argument: Argument::DEFAULT,
        track_identifier: TrackIdentifier::DEFAULT
      )
    end

    def switch_to(specified_track)
      vector[:track_identifier] = lambda do |operation, track_identifier|
        if specified_track.is_a?(Proc)
          specified_track.(operation, track_identifier)
        else
          specified_track
        end
      end
    end

    def successor_track
      lambda do |operation, track_identifier|
        operation.successor_track(track_identifier)
      end
    end
  end
end
