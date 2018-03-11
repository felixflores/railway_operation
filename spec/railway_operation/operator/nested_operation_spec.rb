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

  nest operation(:variation2)
  add_step 0, :method6
end

describe 'nested operation RailwayOperation::Operator' do
  it 'allows variations to exist' do
    result, _info = NestedExample.run_variation1({})
    expect(result['value']).to eq([:method2, :method3, :method4])
  end

  it 'allows operations to be nested' do
    result, _info = NestedExample.run_variation2({})
    expect(result['value']).to eq([:method1, :method2, :method3, :method4, :method5])
  end

  it 'allows named operations to be nested to the default operation' do
    result, _info = NestedExample.run({})
    expect(result['value']).to eq(
      [:method1, :method2, :method3, :method4, :method5, :method6]
    )
  end
end
