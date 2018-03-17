# frozen_string_literal: true

require 'spec_helper'

module Readme
  class FailingStep
    include RailwayOperation

    class MyError < StandardError; end
    class HaltingOperation < StandardError; end

    alias_tracks alias1: 1, alias2: 3, error_track: 2

    stepper_function Strategy.capture(MyError, error_track: :error_track)

    add_step :alias1, :method_1
    add_step :alias2, :method_2
    add_step :alias1, :method_3
    add_step :alias1, :method_4
    add_step :error_track, :log_error

    def initialize(someone = 'someone')
      @someone = someone
    end

    def method_1(argument, **_info)
      argument << 1
    end

    def method_2(argument, **_info)
      argument << 2
    end

    def method_3(argument, **_info)
      argument << 3
    end

    def method_4(argument, **_info)
      raise MyError, 'uh oh'
    end

    def log_error(argument, **)
      argument << :error
    end
  end
end

describe 'Failing Step' do
  it 'uses pessimistic strategy' do
    result, info = Readme::FailingStep.run([])
    expect(result).to eq([:error])
  end
end
