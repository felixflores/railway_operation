# frozen_string_literal: true

require 'spec_helper'

class HappyPath
  include RailwayOperation::Operator

  add_step 1, :step1
  add_step 1, :step2
  add_step 1, :step3

  def step1(argument, **_info)
    argument << :step1
  end

  def step2(argument, **_info)
    argument << :step2
  end

  def step3(argument, **_info)
    argument << :step3
  end
end

class NoSteps
  include RailwayOperation::Operator
end

describe 'smoke test RailwayOperation::Operator' do
  describe '.run' do
    it 'executes the steps in the operation' do
      result, info = HappyPath.run([])

      expect(result).to eq([:step1, :step2, :step3])
      expect(RailwayOperation::Info.execution(info)).to eq(
        [
          { track_identifier: 1, step_index: 0, argument: [], noop: false, method: :step1, succeeded: true },
          { track_identifier: 1, step_index: 1, argument: [:step1], noop: false, method: :step2, succeeded: true },
          { track_identifier: 1, step_index: 2, argument: [:step1, :step2], noop: false, method: :step3, succeeded: true }
        ]
      )
    end

    it 'does not mutate arguments passed to the operation' do
      argument = ["don't change"]
      result, info = HappyPath.run(argument)

      expect(argument).to eq(["don't change"])
      expect(result).to eq(["don't change", :step1, :step2, :step3])

      expect(RailwayOperation::Info.execution(info)[0]).to include(argument: ["don't change"], noop: false, succeeded: true)
      expect(RailwayOperation::Info.execution(info)[1]).to include(argument: ["don't change", :step1], noop: false, succeeded: true)
      expect(RailwayOperation::Info.execution(info)[2]).to include(argument: ["don't change", :step1, :step2], noop: false, succeeded: true)
    end

    it 'does nothing when no steps are specified' do
      argument = 'noop'
      result, info = NoSteps.run(argument)

      expect(result).to eq(argument)
      expect(RailwayOperation::Info.execution(info)[0]).to be_nil
    end
  end
end
