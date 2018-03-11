# frozen_string_literal: true

require 'spec_helper'

class HappyPath < InfiniteSteps
  add_step 0, :step1
  add_step 0, :step2
  add_step 0, :step3
end

class NoSteps
  include RailwayOperation::Operator
end

describe 'smoke test RailwayOperation::Operator' do
  describe '.run' do
    it 'executes the steps in the operation' do
      result, info = HappyPath.run({})

      expect(result['value']).to eq([:step1, :step2, :step3])
      expect(info.execution).to eq(
        [
          { track_identifier: 0, step_index: 0, argument: {} },
          { track_identifier: 0, step_index: 1, argument: { 'value' => [:step1] } },
          { track_identifier: 0, step_index: 2, argument: { 'value' => [:step1, :step2] } },
          { track_identifier: 0, step_index: 3, argument: { 'value' => [:step1, :step2, :step3] } }
        ]
      )
    end

    it 'does not mutate arguments passed to the operation' do
      argument = { 'original_value' => "don't change" }
      result, _info = HappyPath.run(argument)

      expect(argument).to eq('original_value' => "don't change")
      expect(result).to eq(
        'original_value' => "don't change",
        'value' => [:step1, :step2, :step3]
      )
    end

    it 'can accept splatted hash' do
      result, _info = HappyPath.run(original: :value)
      expect(result).to eq(
        original: :value,
        'value' => [:step1, :step2, :step3]
      )
    end

    it 'does nothing when no steps are specified' do
      argument = 'noop'
      result, _info = NoSteps.run(argument)

      expect(result).to eq(argument)
    end
  end
end
