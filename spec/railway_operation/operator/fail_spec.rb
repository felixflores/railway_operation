# frozen_string_literal: true

require 'spec_helper'

class MultiplePath < InfiniteSteps
  add_step 0, :step1
  add_step 1, :step2
  add_step 0, :step3
end

class StepFailure < InfiniteSteps
  add_step 0, :step0_0
  add_step 1, :fail1_1
  add_step 0, :step0_2
  add_step 1, :fail1_3
  add_step 2, :step2_4

  def step0_2(argument, **)
    argument['first_mutations'] = true
    fail_step!
  end
end

class FailOperationMidStep < InfiniteSteps
  add_step 0, :step1
  add_step 0, :step2
  add_step 0, :step3

  def step2(argument, **_info)
    argument['value'] << 2.1
    fail_operation!
    argument['value'] << 2.2
  end
end

describe 'fail RailwayOperation::Operator' do
  describe '.run' do
    context 'multiple tracks defined' do
      it 'remains on the same track if step does not fail' do
        result, _info = MultiplePath.run({})
        expect(result).to eq('value' => [:step1, :step3])
      end

      context 'step failure' do
        let(:failure_steps) do
          { 'value' => [:step0_0, :fail1_3] }
        end
        it 'moves to the track 1 index higher' do
          result, _info = StepFailure.run({})
          expect(result).to eq(failure_steps)
        end

        it 'rolls back any mutations' do
          original_argument = { original: 'af' }

          result, _info = StepFailure.run(original_argument)
          expect(result).to eq(original_argument.merge(failure_steps))
        end
      end

      context 'fail operation' do
        let(:argument) { { the: :agument } }

        it 'does not maintain any changes to the argument' do
          result, _info = FailOperationMidStep.run(argument)
          expect(result).to eq(argument)
        end
      end
    end
  end
end
