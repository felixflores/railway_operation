# frozen_string_literal: true

require 'spec_helper'

class HappyPath
  include RailwayOperation::Operator

  add_step 0, :step1
  add_step 0, :step2
  add_step 0, :step3

  def step1(argument, **_info)
    argument << :step1
    argument
  end

  def step2(argument, **_info)
    argument << :step2
    argument
  end

  def step3(argument, **_info)
    argument << :step3
    argument
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
      expect(info.execution).to eq(
        [
          { track_identifier: 0, step_index: 0, argument: [], noop: false },
          { track_identifier: 0, step_index: 1, argument: [:step1], noop: false },
          { track_identifier: 0, step_index: 2, argument: [:step1, :step2], noop: false },
          { track_identifier: 0, step_index: 3, argument: [:step1, :step2, :step3], noop: true }
        ]
      )
    end

    it 'does not mutate arguments passed to the operation' do
      argument = ["don't change"]
      result, info = HappyPath.run(argument)

      expect(argument).to eq(["don't change"])
      expect(result).to eq(["don't change", :step1, :step2, :step3])
      expect(info.execution).to eq(
        [
          { track_identifier: 0, step_index: 0, argument: ["don't change"], noop: false },
          { track_identifier: 0, step_index: 1, argument: ["don't change", :step1], noop: false },
          { track_identifier: 0, step_index: 2, argument: ["don't change", :step1, :step2], noop: false },
          { track_identifier: 0, step_index: 3, argument: ["don't change", :step1, :step2, :step3], noop: true }
        ]
      )
    end

    it 'can accept splatted hash' do
      result, info = HappyPath.run([:original])

      expect(result).to eq([:original, :step1, :step2, :step3])
      expect(info.execution).to eq(
        [
          { track_identifier: 0, step_index: 0, argument: [:original], noop: false },
          { track_identifier: 0, step_index: 1, argument: [:original, :step1], noop: false },
          { track_identifier: 0, step_index: 2, argument: [:original, :step1, :step2], noop: false },
          { track_identifier: 0, step_index: 3, argument: [:original, :step1, :step2, :step3], noop: true }
        ]
      )
    end

    it 'does nothing when no steps are specified' do
      argument = 'noop'
      result, info = NoSteps.run(argument)

      expect(result).to eq(argument)
      expect(info.execution).to eq(
        [{ track_identifier: 0, step_index: 0, argument: 'noop', noop: true }]
      )
    end
  end
end
