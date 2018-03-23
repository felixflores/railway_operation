# frozen_string_literal: true

require 'table_print'

module RailwayOperation
  class Strategy
    DEFAULT = lambda do |stepper, info, *errors, error_track: nil, &step|
      begin
        _result, new_info = step.call

        if new_info.execution.last_step[:errors]
          stepper.fail_step
          stepper.switch_to(error_track || stepper.successor_track)
        else
          stepper.continue
        end
      rescue => e
        raise(e, stepper.error_message(e, info), e.backtrace) unless errors.include?(e.class)

        (new_info || info).execution.last_step.errors << { exception: e }
        stepper.fail_step
        stepper.switch_to(error_track || stepper.successor_track)
      end
    end

    def self.capture(*errors, error_track:)
      lambda do |stepper, info, &step|
        Strategy::DEFAULT.(stepper, info, *errors, error_track: error_track, &step)
      end
    end
  end
end
