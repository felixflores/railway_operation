# frozen_string_literal: true

require 'spec_helper'

describe RailwayOperation::Stepper do
  context 'vectors' do
    context 'Argument' do
      context 'DEFAULT' do
        it 'returns argument' do
          argument = 1
          expect(described_class::Argument::DEFAULT.call(argument, {})).to equal(argument)
        end
      end

      context 'FAIL_OPERATION' do
        it 'returns the argument from the first step' do
          first_argument = 1
          second_argument = 2

          info = RailwayOperation::Info.new(
            operation: 'op',
            execution: [
              RailwayOperation::Step.new(argument: first_argument),
              RailwayOperation::Step.new(argument: second_argument)
            ]
          )

          expect(described_class::Argument::FAIL_OPERATION.call('a', info)).to equal(first_argument)
        end
      end
    end

    context 'TrackIdentifier' do
      context 'DEFAULT' do
        it 'returns the track identifier'
      end

      context 'NOOP' do
        it 'returns the noop track'
      end
    end

    context 'StepIndex' do
      context 'DEFAULT'
    end
  end

  describe '.step'
  describe '#[]'
  describe '#step'
  describe '#halt_operation'
  describe '#fail_operation'
  describe '#fail_step'
  describe '#continue'
  describe '#switch_to'
  describe '#successor_track'
  describe '#error_message'
end
