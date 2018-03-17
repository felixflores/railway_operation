# frozen_string_literal: true

require 'table_print'

module RailwayOperation
  class Strategy
    DEFAULT = lambda do |stepper, info, *errors, error_track: nil, &step|
      begin
        _result, new_info = step.call

        if Info.last_step(new_info)[:errors]
          stepper.fail_step
          stepper.switch_to(error_track || stepper.successor_track)
        else
          stepper.continue
        end
      rescue => e
        stepper.raise_error(e, info) unless errors.include?(e.class)

        Info.last_step(new_info || info)[:succeeded] = false
        stepper.fail_operation
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
