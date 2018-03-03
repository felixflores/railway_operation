# frozen_string_literal: true

require 'spec_helper'

describe RailwayOperation::FilledMatrix do
  context 'accessor' do
    let(:m) { described_class.new([1, 2], [3, 4]) }

    it 'first argument is row' do
      expect(m[0, 0]).to eq(1)
      expect(m[1, 0]).to eq(3)
    end

    it 'second argument is column' do
      expect(m[0, 0]).to eq(1)
      expect(m[0, 1]).to eq(2)
    end
  end

  it 'accessing non-existent entry returns nil' do
    m = described_class.new
    expect(m[2, 3]).to eq(nil)
  end

  it 'matrix can be initialized with rows' do
    m = described_class.new([1, 2], [3, 4])

    expect(m[0, 0]).to eq(1)
    expect(m[0, 1]).to eq(2)
    expect(m[1, 0]).to eq(3)
    expect(m[1, 1]).to eq(4)
  end

  it 'accessing matrix does not change matrix' do
    empty_matrix = described_class.new
    non_empty_matrix = described_class.new([1, 2], [3, 4])
    empty_matrix[2, 3]
    non_empty_matrix[1, 1]

    expect(empty_matrix.to_a).to eq([])
    expect(non_empty_matrix.to_a).to eq([[1, 2], [3, 4]])
  end

  context 'row lengths' do
    it 'is ensure to be equal after initilization' do
      unevent_declaration = described_class.new([1, 2], [3])
      expect(unevent_declaration.to_a).to eq([[1, 2], [3, nil]])
    end

    it 'ensures rows are equal after assignment' do
      m = described_class.new([1, 2], [3, 4])
      m[1, 2] = 5

      expect(m.to_a).to eq([[1, 2, nil], [3, 4, 5]])
    end
  end

  context 'assignment' do
    it 'overrides existing entry' do
      m = described_class.new([1, 2], [3, 4])
      m[1, 1] = 100

      expect(m.to_a).to eq(
        [
          [1, 2],
          [3, 100]
        ]
      )
    end

    it 'permits arbitrary positions assignment, ensuring rows are even' do
      m = described_class.new([1, 2], [3, 4])
      m[3, 5] = 100

      expect(m.to_a).to eq(
        [
          [1, 2, nil, nil, nil, nil],
          [3, 4, nil, nil, nil, nil],
          [nil, nil, nil, nil, nil, nil],
          [nil, nil, nil, nil, nil, 100]
        ]
      )
    end
  end
end
