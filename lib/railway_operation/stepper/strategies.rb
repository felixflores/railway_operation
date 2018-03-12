# frozen_string_literal: true

module RailwayOperation
  module Strategies
    PESSIMISTIC = lambda do |stepper, &step|
      _, info = step.call

      if info.current_step[:error]
        stepper.fail_operation
      else
        stepper.continue
      end
    end

    OPTIMISTIC = lambda do |stepper, &step|
      _, info = step.call

      if info.current_step[:error].present?
        stepper.fail_step
        stepper.switch_to(stepper.successor_track)
      else
        stepper.continue
      end
    end
  end
end
