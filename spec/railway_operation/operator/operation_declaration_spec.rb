# frozen_string_literal: true

require 'spec_helper'

class Sample < InfiniteSteps
  operation(:variation1) do |o|
    o.add_step 1, :method3
    o.add_step 1, :method2
    o.add_step 1, :method1
  end

  add_step 1, :method1
  add_step 1, :method2
  add_step 1, :method3
end

describe 'operation declaration RailwayOperation::Operator' do
  it 'allows default operation to be defined implicitly' do
    result, _info = Sample.run({})
    expect(result['value']).to eq([:method1, :method2, :method3])

    result_missing_method, _info = Sample.run_default({})
    expect(result_missing_method).to eq(result)
  end

  it 'allow operation declaration using block syntax' do
    result, _info = Sample.run_variation1({})
    expect(result['value']).to eq([:method3, :method2, :method1])
  end
end
