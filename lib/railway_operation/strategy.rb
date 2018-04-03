# frozen_string_literal: true

module RailwayOperation
  class Strategy
    DEFAULT = lambda do |stepper, info, *error_continues, error_track: nil, &step|
      begin
        _result, new_info = step.call

        if new_info.execution.success?
          stepper.continue
        else
          stepper.fail_step
          stepper.switch_to(error_track || stepper.successor_track)
        end
      rescue => e
        (new_info || info).execution.last.fail!(exception: e)
        raise(e, stepper.error_message(e, info), e.backtrace) unless error_continues.include?(e.class)

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
