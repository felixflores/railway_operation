# frozen_string_literal: true

require 'spec_helper'

describe RailwayOperation::Operation do
  let(:subject) { described_class.new('Operation sample') }

  context '#fails_step' do
    it 'allows error classes to be pushed into fails_step declaration' do
      subject.fails_step << StandardError
      expect(subject.fails_step.to_a).to eq([StandardError])
    end

    it 'does not allow non error classes to be pushed into fails_step' do
      expect { subject.fails_step << {} }.to(
        raise_error(RailwayOperation::TypedArray::UnacceptableMember)
      )
    end
  end

  context '#name' do
    let(:operation1) { described_class.new('operation_name') }
    let(:operation2) { described_class.new('operation name') }
    let(:operation3) { described_class.new(:operation_name) }
    let(:operation4) { described_class.new('Operation name') }

    context '#step_surrounds'

    it 'returns the name in underscore format' do
      expect(subject.name).to eq(:operation_sample)
      expect(operation1.name).to eq(:operation_name)
      expect(operation2.name).to eq(:operation_name)
      expect(operation3.name).to eq(:operation_name)
      expect(operation4.name).to eq(:operation_name)
    end
  end

  context '#operation_surrounds' do
    it 'is a SurroundsArray' do
      expect(subject.operation_surrounds).to be_a(Array)
    end
  end

  context '#step_surrounds' do
    it 'is an EnsuredAccess hash' do
      expect(subject.step_surrounds).to be_a(RailwayOperation::EnsuredAccess)
      expect(subject.step_surrounds.__getobj__).to be_a(Hash)
    end

    it 'has a default value of an empty SurroundsArray' do
      expect(subject.step_surrounds['random']).to be_a(RailwayOperation::StepsArray)
      expect(subject.step_surrounds['random']).to be_empty
    end
  end

  context '#track_alias' do
    it 'is a hash' do
      expect(subject.track_alias).to be_a(Hash)
    end
  end

  context '#tracks' do
    it 'is a FilledMatrix' do
      expect(subject.tracks).to be_a(RailwayOperation::FilledMatrix)
    end

    it 'is StepsArray ensured access array for each track' do
      expect(subject.tracks[0]).to be_a(RailwayOperation::EnsuredAccess)
      expect(subject.tracks[0].__getobj__).to be_a(RailwayOperation::StepsArray)
    end
  end

  context '#[]' do
    context 'with alias' do
      before do
        subject.track_alias = { 'first' => 0, 'second' => 1, 'third' => 2 }

        subject.add_step(0, :method0)
        subject.add_step('first', :method1)
        subject.add_step(1, :method2)
        subject.add_step('second', :method3)
      end

      it 'resolves the steps according to the alias mapping' do
        expect(subject['first', 0][:method]).to eq(:method0)
        expect(subject['first', 1][:method]).to eq(:method1)
        expect(subject['second', 2][:method]).to eq(:method2)
        expect(subject['second', 3][:method]).to eq(:method3)
      end
    end
  end

  context '#[]=' do
    it 'can be used to assign steps to the step matrix' do
      subject[0, 2] = :method
      expect(subject.tracks[0, 2]).to eq(:method)
    end
  end

  context '#add_step' do
    let(:tracks) do
      [
        [
          { method: :track_0_0, success: nil, failure: nil },
          { method: :track_0_1, success: 2, failure: nil },
          nil,
          { method: :track_0_3, success: 4, failure: nil },
          nil
        ],
        [
          nil,
          nil,
          { method: :track_1_2, success: nil, failure: 1 },
          nil,
          nil
        ],
        [
          nil,
          nil,
          nil,
          nil,
          { method: :track_2_4, success: nil, failure: nil }
        ]
      ]
    end

    it 'declares tracks into a filled matrix' do
      subject.add_step 0, :track_0_0
      subject.add_step 0, :track_0_1, success: 2
      subject.add_step 1, :track_1_2, failure: 1
      subject.add_step 0, :track_0_3, success: 4
      subject.add_step 2, :track_2_4

      subject.tracks.each_with_index do |track, index|
        expect(track).to eq(tracks[index]), "error on #{index}"
      end
    end
  end
end
