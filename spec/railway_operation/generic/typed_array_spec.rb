# frozen_string_literal: true

require 'spec_helper'

describe RailwayOperation::Generic::TypedArray do
  context 'guards' do
    it 'raises an error if initialize with a non array obj' do
      expect { described_class.new({}, ensure_type_is: Numeric) }.to raise_error(
        ArgumentError,
        'must be initialized with an array'
      )
    end

    it 'ensure_type_is is required' do
      expect { described_class.new([]) }.to raise_error(
        ArgumentError,
        'missing keyword: ensure_type_is'
      )
    end

    it 'raises and error if initialized with an array with elements of unacceptable type' do
      arr1 = [1, 2, :three]
      expect { described_class.new(arr1, ensure_type_is: Numeric) }.to raise_error(
        RailwayOperation::Generic::TypedArray::UnacceptableMember,
        'unacceptable element in array, all elements must be of type Numeric'
      )

      arr2 = [1, 2.0, 0x3]
      expect { described_class.new(arr2, ensure_type_is: Numeric) }.to_not raise_error

      arr3 = [Float, Integer, Array]
      expect { described_class.new(ensure_type_is: Numeric).__setobj__(arr3) }.to raise_error(
        RailwayOperation::Generic::TypedArray::UnacceptableMember
      )

      arr4 = [Float, Integer]
      expect { described_class.new(ensure_type_is: Numeric).__setobj__(arr4) }.to_not raise_error
    end

    it 'multiple types to be can be allowed' do
      subject = described_class.new(ensure_type_is: [Numeric, Hash])
      expect { subject << Proc }.to raise_error(
        RailwayOperation::Generic::TypedArray::UnacceptableMember
      )

      expect { subject << 1 }.to_not raise_error
      expect { subject << {} }.to_not raise_error
    end
  end
end
