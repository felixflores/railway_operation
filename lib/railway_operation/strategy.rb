# frozen_string_literal: true

module RailwayOperation
  class Strategy
    DEFAULT = lambda do |stepper, info, &step|
      begin
        _result, new_info = step.call

        if new_info.execution.last.failed?
          stepper.fail_operation
        end

        stepper.continue
      rescue StandardError => e
        stepper.raise_error(e, new_info || info)
      end
    end

    def self.standard
      tracks = [:normal, :error_track, :fail_track]

      stepper_fn = Strategy.norm_exceptional(
        norm: {
          normal: ->(execution) { !execution.errored? },
          error_track: ->(execution) { execution.errored? },
          fail_track: ->(execution) { execution.failed? }
        }
      )

      [tracks, stepper_fn]
    end

    def self.norm_exceptional(norm: {}, exceptional: {})
      lambda do |stepper, _, &step|
        begin
          _, new_info = step.call

          track_switch = norm.detect do |_, predicate|
            predicate.call(new_info.execution)
          end&.first

          stepper.switch_to(track_switch) if track_switch
          stepper.continue
        rescue StandardError => e
          track_switch = exceptional.detect do |_, predicate|
            predicate.call(e)
          end&.first

          stepper.raise_error(e, new_info || info) unless track_switch
          stepper.switch_to(track_switch).continue
        end
      end
    end
  end
end
