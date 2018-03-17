# frozen_string_literal: true

module RailwayOperation
  # This class is responsible for calculating the vector of the next step
  # during an operation execution
  class Stepper
    def self.step(*args, &block)
      new.step(*args, &block)
    end

    module Argument
      DEFAULT = lambda do |argument, _info|
        argument
      end

      FAIL_OPERATION = lambda do |_argument, info|
        Info.first_step(info)[:argument]
      end
    end

    module TrackIdentifier
      DEFAULT = lambda do |info|
        info[:track_identifier]
      end

      NOOP = lambda do |operation:, **|
        operation.noop_track
      end
    end

    module StepIndex
      DEFAULT = lambda do |info|
        Info.last_step(info)[:step_index] + 1
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
      vector.merge!(
        argument: Argument::DEFAULT,
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
      vector[:track_identifier] = lambda do |track_identifier:, operation:, **info|
        begin
          track = case specified_track
                  when Proc
                    specified_track.call(operation, track_identifier)
                  else
                    specified_track
                  end

          operation.track_index(track) # ensures that track index is found in the operation
          TrackIdentifier::DEFAULT.(info.merge(operation: operation, track_identifier: track))
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

    def raise_error(e, info)
      Info.last_step(info)[:succeeded] = false
      step_index = Info.execution(info).length - 1
      track_identifier = Info.last_step(info)[:track_identifier]

      message = "The operation was aborted because `#{e.class}' "\
        "was raised on track #{track_identifier}, step #{step_index} of the operation."\
        "\n\n"\
        "#{TablePrint::Printer.table_print(Info.execution(info))}"

      raise e, message, e.backtrace
    end
  end
end
