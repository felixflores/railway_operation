# frozen_string_literal: true

require 'spec_helper'

module Readme
  class FailingStep
    include RailwayOperation::Operator
    class MyError < StandardError; end
    class HaltingOperation < StandardError; end

    alias_tracks alias1: 1, alias2: 2, alias3: 3

    stepper_function do |stepper, &step|
      begin
        step.call
        stepper.continue
      rescue HaltingOperation
        stepper.halt_operation
      rescue MyError
        stepper.fail_step
        stepper.switch_to(stepper.successor_track)
      end
    end

    add_step :alias1, :first_method
    add_step :alias1, :another_method
    add_step :alias1, :final_method
    add_step :alias2, :log_error

    def initialize(someone = 'someone')
      @someone = someone
    end

    def first_method(argument, **_info)
      argument << 1
    end

    def another_method(_argument, **)
      raise MyError, 'uh oh'
    end

    def final_method(argument, **)
      argument << 3
    end

    def log_error(argument, **)
      argument << :error
    end
  end
end

describe 'Failing Step' do
  it 'uses pessimistic strategy' do
    result, _info = Readme::FailingStep.run([])
    expect(result).to eq([:error])
  end
end
