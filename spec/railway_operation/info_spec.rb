# frozen_string_literal: true

require 'spec_helper'

describe RailwayOperation::Info do
  let(:operation) { instance_double(RailwayOperation::Operation) }
  let(:subject) do
    described_class.new(
      operation: operation,
      track_identifier: :default,
      step_index: 0
    )
  end

  context 'constructor' do
    it 'constructor is idempotent' do
      expect(described_class.new(subject)).to eq(subject)
    end

    it 'expects operation, track_identifier, and step_index' do
      expect{ described_class.new }.to raise_error(
        ArgumentError,
        'missing keyword: operation'
      )
    end
  end

  context 'accessors' do
    it 'can access operation' do
      subject.operation = 1
      expect(subject.operation).to eq(1)
    end

    context '#execution' do
      it 'ensures that execution is an instance of Execution' do
        expect(subject.execution).to be_a_kind_of(RailwayOperation::Execution)
      end

      it 'coerses self[:execution] to be an instance of Execution' do
        subject[:execution] = []
        expect(subject.execution).to be_a_kind_of(RailwayOperation::Execution)
      end

      context 'execution accessors' do
        let(:execution) { subject.execution }

        it 'contructor is idempotent' do
          s1 = RailwayOperation::Execution.new
          expect(RailwayOperation::Execution.new(s1)).to eq(s1)
        end

        it 'is a delegated array' do
          expect(execution).to eq([])
        end

        it 'converts ensures that each element of the execution is a Step' do
          execution << { fact: 1 }
          execution << { fact: 2 }

          expect(execution.first_step).to be_a_kind_of(RailwayOperation::Step)
          expect(execution.first_step[:fact]).to eq(1)

          expect(execution.last_step).to be_a_kind_of(RailwayOperation::Step)
          expect(execution.last_step[:fact]).to eq(2)

          execution[2] = { fact: 3 }

          expect(execution.last_step).to be_a_kind_of(RailwayOperation::Step)
          expect(execution.last_step[:fact]).to eq(3)
        end

        it 'is success if all steps succeeded' do
          execution << { errors: [] }
          execution << { errors: [] }
          execution << { errors: [] }

          expect(execution).to be_success

          execution << { errors: [1] }
          expect(execution).to_not be_success
        end

        it 'is completed if all all steps completed' do
          execution << { started_at: 1, ended_at: 1 }
          execution << { started_at: 1, ended_at: 1 }
          execution << { started_at: 1, ended_at: 1 }

          expect(execution).to be_completed

          execution << { started_at: 1, ended_at: nil }
          expect(execution).to_not be_completed
        end

        it 'can add_step with require fields' do
          expect{ execution.add_step }.to raise_error('missing keywords: argument, track_identifier, step_index')
          expect(execution.add_step(argument: 1, track_identifier: 2, step_index: 3)).to be_a_kind_of(RailwayOperation::Step)
        end
      end

      context 'execution steps' do
        let(:step) do
          subject.execution << { fact: 1 }
          subject.execution[0]
        end

        it 'contructor is idempotent' do
          s1 = RailwayOperation::Step.new
          expect(RailwayOperation::Step.new(s1)).to eq(s1)
        end

        it 'can mark steps started_at time' do
          expect(step.started_at).to be_nil

          step.start!
          expect(step.started_at).to be_a_kind_of(Time)
          expect(step).to be_started
        end

        it 'can mark steps ended_at time' do
          expect(step.ended_at).to be_nil

          step.start!
          step.end!
          expect(step.ended_at).to be_a_kind_of(Time)
          expect(step).to be_completed
        end

        it 'can mark steps as noop' do
          step.noop!
          expect(step.ended_at).to be_a_kind_of(Time)
          expect(step.started_at).to be_a_kind_of(Time)
          expect(step).to be_noop
        end

        it 'cannot end step that has not started' do
          expect(step.started_at).to be_nil
          expect { step.end! }.to raise_error('cannot complete step that has not yet started')
        end

        it 'completed at is equivalent to ended_at' do
          step[:ended_at] = 3
          expect(step.completed_at).to eq(3)
        end
      end
    end
  end

  context '#display' do
    let(:subject) { described_class.new(operation: nil) }

    it 'can display an empty info' do
      expect(subject.display).to eq(
        "+--+-------+---------+--------+--------+\n"\
        "|              Execution               |\n"\
        "+--+-------+---------+--------+--------+\n"\
        "|  | Track | Success | Method | Errors |\n"\
        "+--+-------+---------+--------+--------+\n"\
        '+--+-------+---------+--------+--------+'
      )
    end

    it 'can display info with step' do
      subject.execution << { track_identifier: 1, step_index: 0 }
      expect(subject.display).to eq(
        "+---+-------+---------+--------+--------+\n"\
        "|               Execution               |\n"\
        "+---+-------+---------+--------+--------+\n"\
        "|   | Track | Success | Method | Errors |\n"\
        "+---+-------+---------+--------+--------+\n"\
        "| 0 | 1     | true    |        | []     |\n"\
        '+---+-------+---------+--------+--------+'
      )
    end
  end
end
