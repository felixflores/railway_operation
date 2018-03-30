# frozen_string_literal: true

require 'spec_helper'

describe RailwayOperation::StepsArray do
  context '#operation_surrounds' do
    it 'allows symbols to be pushed' do
      expect { subject << :method }.to_not raise_error
    end

    it 'allows symbols to be pushed' do
      expect { subject << 'method' }.to_not raise_error
    end

    it 'allows arrays to be pushed' do
      expect { subject << [] }.to_not raise_error
    end

    it 'allows procs to be pushed' do
      expect { subject << -> { 1 } }.to_not raise_error
    end

    it 'does not allow any other types' do
      expect { subject << 1 }.to raise_error(
        RailwayOperation::Generic::TypedArray::UnacceptableMember
      )

      expect { subject << {} }.to raise_error(
        RailwayOperation::Generic::TypedArray::UnacceptableMember
      )

      expect { subject << 1.2 }.to raise_error(
        RailwayOperation::Generic::TypedArray::UnacceptableMember
      )

      expect { subject << Object }.to raise_error(
        RailwayOperation::Generic::TypedArray::UnacceptableMember
      )
    end
  end
end
