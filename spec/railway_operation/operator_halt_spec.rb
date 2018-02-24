# frozen_string_literal: true

require 'spec_helper'

class MidStepHalt < InfiniteSteps
  track 0, :step1
  track 0, :step2
  track 0, :step3

  def step2(argument)
    argument['value'] << 2.1
    halt_step!
    argument['value'] << 2.2
  end
end

class HaltOperationMidStep < InfiniteSteps
  track 0, :step1
  track 0, :step2
  track 0, :step3

  def step2(argument)
    argument['value'] << 2.1
    halt_operation!
    argument['value'] << 2.2
  end
end

describe 'halt RailwayOperation::Operator' do
  context 'halt step' do
    it 'maintains within step so far and continues to next step' do
      result = MidStepHalt.run({})
      expect(result['value']).to eq([:step1, 2.1, :step3])
    end
  end

  context 'halt operation' do
    it 'maintains within step so far and does not continue to next step' do
      result = HaltOperationMidStep.run({})
      expect(result['value']).to eq([:step1, 2.1])
    end
  end
end
