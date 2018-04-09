# frozen_string_literal: true

require 'spec_helper'

module RailwayOperation
  class TestOperator
    extend Operator::ClassMethods
    include Operator::InstanceMethods
  end
end

describe RailwayOperation::TestOperator do
  context 'ClassMethods' do
    describe '.operation' do
      it "creates the operation with the supplied name if it's not found" do
        name = "unknown_operation#{rand(50)}".to_sym
        op = described_class.operation(name)

        expect(op).to be_a(RailwayOperation::Operation)
        expect(op.name).to eq(name)
      end

      it 'retuns the default operation if no arguments is supplied' do
        op = described_class.operation

        expect(op).to be_a(RailwayOperation::Operation)
        expect(op.name).to eq(:default)
      end

      it 'accepts a symbol or an operation' do
        operation1 = RailwayOperation::Operation.new(:test1)
        expect(described_class.operation(operation1)).to equal(operation1)

        operation2 = described_class.operation(:test2)
        expect(operation2.name).to eq(:test2)
      end

      it 'yields the operation to the given block' do
        operation = RailwayOperation::Operation.new(:test)

        described_class.operation(operation) do |op|
          expect(op).to equal(operation)
        end
      end
    end

    describe '.run' do
      it 'delegates to #run' do
        argument = 1
        options = { operation: 2, something: 3 }

        expect_any_instance_of(described_class).to receive(:run)
          .with(argument, options)

        described_class.run(argument, options)
      end

      it 'curries the call to #run with operation :default if not supplied' do
        argument = 1
        options = { something: 3 }

        expect_any_instance_of(described_class).to receive(:run)
          .with(argument, options.merge(operation: :default))

        described_class.run(argument, options)
      end
    end

    describe 'metaprogramming' do
      it 'allows run to be called with operation suffix' do
        argument = 1
        options = { something: 3 }

        expect_any_instance_of(described_class).to receive(:run)
          .with(argument, options.merge(operation: 'something'))

        expect(described_class.respond_to?(:run_something)).to eq(true)
        described_class.run_something(argument, options)
      end

      it 'raises an error unless the missing method called is prefixed with run' do
        expect(described_class.respond_to?(:something_random)).to eq(false)
        expect { described_class.something_random }.to raise_error(
          NoMethodError,
          /undefined method `something_random\'/
        )
      end
    end
  end

  context 'InstanceMethods' do
    describe '#run' do
      let(:argument) { {} }

      it 'defines default values for operation, track_identifier, and step_index' do
        info = instance_double(RailwayOperation::Info)

        # Uses default operation if not specified
        expect(RailwayOperation::Info).to receive(:new).with(
          hash_including(operation: described_class.operation(:default))
        ).and_return(info)

        # Defaults to track_identifier 1
        # Defaults to step_index 0
        expect(subject).to receive(:_run).with(
          argument,
          info,
          track_identifier: 1,
          step_index: 0
        )

        subject.run(argument)
      end

      it 'wraps _run with operation surrounds' do
        op = described_class.operation
        op.operation_surrounds = [:method1, :method2]

        expect(subject).to receive(:wrap).with(:method1, :method2)
        subject.run(argument)
      end
    end

    describe '#run_step' do
      let(:argument) { {} }

      it 'defines default value for operation' do
        expect(subject).to receive(:_run_step).with(
          argument,
          kind_of(RailwayOperation::Info)
        )

        subject.run_step(argument, track_identifier: 1, step_index: 1)
      end

      it 'requires track_identifier and step_index to be specified' do
        expect { subject.run_step(argument) }.to raise_error(
          ArgumentError,
          'missing keywords: track_identifier, step_index'
        )
      end
    end
  end
end
