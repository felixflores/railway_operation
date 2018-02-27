# frozen_string_literal: true

require 'spec_helper'

class Sample < InfiniteSteps
  operation(:variation1) do |o|
    o.track 0, :method3
    o.track 0, :method2
    o.track 0, :method1
  end

  track 0, :method2, operation: :variation2
  track 0, :method1, operation: :variation2
  track 0, :method3, operation: :variation2

  op = operation(:variation3)
  track 0, :method1, operation: op
  track 0, :method1, operation: op
  track 0, :method3, operation: op

  track 0, :method1
  track 0, :method2
  track 0, :method3
end

describe 'operation declaration RailwayOperation::Operator' do
  it 'allows default operation to be defined implicitly' do
    result = Sample.run({})
    expect(result['value']).to eq(%i[method1 method2 method3])

    result_missing_method = Sample.run_default({})
    expect(result_missing_method).to eq(result)
  end

  it 'allow operation declaration using operation option' do
    result = Sample.run_variation2({})
    expect(result['value']).to eq(%i[method2 method1 method3])
  end

  it 'allow operation declaration using block syntax' do
    result = Sample.run_variation1({})
    expect(result['value']).to eq(%i[method3 method2 method1])
  end

  it 'allows inline operation declaration' do
    result = Sample.run_variation3({})
    expect(result['value']).to eq(%i[method1 method1 method3])
  end
end
