# frozen_string_literal: true

require 'spec_helper'

describe RailwayOperation::Formatter do
  let(:operation1) do
    op = RailwayOperation::Operation.new(:sample)
    op.alias_tracks('Operation 1' => 0, 'Operation 2' => 1)

    op.add_step(0, :method1)
    op.add_step(0, :method2)
    op.add_step(0, :method3)
    op.add_step(1, :method4)
    op.add_step(1, :method5)
    op.add_step(1, :method6)
    op
  end

  it 'renders graph' do
    expect(described_class.new(operation: operation1).render).to be_nil
  end
end
