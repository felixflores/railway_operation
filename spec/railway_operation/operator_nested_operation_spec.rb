# frozen_string_literal: true

require 'spec_helper'

class NestedExample < InfiniteSteps
  operation(:variation1) do |o|
    o.add_step 0, :method2
    o.add_step 0, :method3
    o.add_step 0, :method4
  end

  operation(:variation2) do |o|
    o.add_step 0, :method1
    o.nest operation(:variation1)
    o.add_step 0, :method5
  end
end

describe 'nested operation RailwayOperation::Operator' do
  it 'allows operations to be nested' do
    result = NestedExample.run_variation2({})
    expect(result['value']).to eq(%i[method1 method2 method3 method4 method5])
  end
end
