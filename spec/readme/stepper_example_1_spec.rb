# frozen_string_literal: true

require 'spec_helper'

module Readme
  class FailingStep
    include RailwayOperation

    class MyError < StandardError; end
    class HaltingOperation < StandardError; end

    operation do |o|
      o.tracks :alias1, :alias2, :error_track
      o.stepper_function Strategy.capture(MyError, error_track: :error_track)

      o.add_step :alias1, :method_1
      o.add_step :alias2, :method_2
      o.add_step :alias1, :method_3
      o.add_step :alias1, :method_4
      o.add_step :error_track, :log_error
    end

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
      argument << 4
    end

    def log_error(argument, **)
      argument << :error
    end
  end
end

describe 'Normal execution' do
  it 'uses capture strategy' do
    result, _info = Readme::FailingStep.run([])
    expect(result).to eq([1, 3, 4])
  end
end
