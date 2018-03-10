# frozen_string_literal: true

require 'spec_helper'

class HaltOperationMidStep < InfiniteSteps
  add_step 0, :step1
  add_step 0, :step2
  add_step 0, :step3

  def step2(argument, **info)
    argument['value'] << 2.1
    halt_operation!(argument)
    argument['value'] << 2.2

    [argument, info]
  end
end

describe 'halt RailwayOperation::Operator' do
  context 'halt operation' do
    it 'maintains within step so far and does not continue to next step' do
      result, _info = HaltOperationMidStep.run({})
      expect(result['value']).to eq([:step1, 2.1])
    end
  end
end
