# frozen_string_literal: true

require 'spec_helper'

describe RailwayOperation::Generic::EnsuredAccess do
  it 'delegates to an object' do
    subject = described_class.new([])
    expect(subject).to eq([])
  end

  it 'allows default values for enumerable objects' do
    subject1 = described_class.new([], 1)
    expect(subject1[rand(100)]).to eq(1)

    subject2 = described_class.new({}, 2)
    expect(subject2[[:a, :b, :c][rand(2)]]).to eq(2)
  end

  it 'default value can be declared with block' do
    subject = described_class.new([]) { {} }
    h1 = subject[0]
    h2 = subject[1]

    expect(h1).to eq({})
    expect(h2).to eq({})
    expect(h2).to_not equal(h1)
  end

  it 'delegated object can be accessed' do
    arr1 = []
    arr2 = []
    subject = described_class.new(arr1, 1)

    expect(subject.__getobj__).to equal(arr1)

    subject.__setobj__(arr2)
    expect(subject.__getobj__).to_not equal(arr1)
    expect(subject.__getobj__).to equal(arr2)
  end
end
