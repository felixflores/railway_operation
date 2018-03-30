# frozen_string_literal: true

require 'spec_helper'

describe RailwayOperation::Operation do
  let(:subject) { described_class.new('Operation sample') }

  context '#name' do
    let(:operation1) { described_class.new('operation_name') }
    let(:operation2) { described_class.new('operation name') }
    let(:operation3) { described_class.new(:operation_name) }
    let(:operation4) { described_class.new('Operation name') }
    let(:operation5) { described_class.new(operation4) }

    context '#step_surrounds'

    it 'returns the name in underscore format' do
      expect(subject.name).to eq(:operation_sample)
      expect(operation1.name).to eq(:operation_name)
      expect(operation2.name).to eq(:operation_name)
      expect(operation3.name).to eq(:operation_name)
      expect(operation4.name).to eq(:operation_name)

      expect(described_class.format_name(operation4)).to eq(:operation_name)
    end
  end

  context '#operation_surrounds' do
    it 'is a SurroundsArray' do
      expect(subject.operation_surrounds).to be_a(Array)
    end
  end

  context '#step_surrounds' do
    it 'is an EnsuredAccess hash' do
      expect(subject.step_surrounds).to be_a(RailwayOperation::Generic::EnsuredAccess)
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
      expect(subject.tracks).to be_a(RailwayOperation::Generic::FilledMatrix)
    end

    it 'is StepsArray ensured access array for each track' do
      expect(subject.tracks[0]).to be_a(RailwayOperation::Generic::EnsuredAccess)
      expect(subject.tracks[0].__getobj__).to be_a(RailwayOperation::StepsArray)
    end
  end

  context '#[]' do
    context 'with alias' do
      before do
        subject.tracks 'first', 'second', 'third'

        subject.add_step(1, :method0)
        subject.add_step('first', :method1)
        subject.add_step(2, :method2)
        subject.add_step('second', :method3)
      end

      it 'resolves the steps according to the alias mapping' do
        expect(subject[1, 0]).to eq(:method0)
        expect(subject['first', 1]).to eq(:method1)
        expect(subject[2, 2]).to eq(:method2)
        expect(subject['second', 3]).to eq(:method3)
      end
    end
  end

  context '#stepper_function' do
    let(:fn) { lambda {} }
    it 'sets and gets stepper_function' do
      subject.stepper_function(fn)
      expect(subject.stepper_function).to equal(fn)
    end

    it 'can be set using block syntax' do
      subject.stepper_function(&fn)
      expect(subject.stepper_function).to eq(fn)
    end
  end

  context '#[]=' do
    it 'can be used to assign steps to the step matrix' do
      subject[1, 2] = :method
      expect(subject.tracks[1, 2]).to eq(:method)
    end
  end

  context '#add_step' do
    it 'declares tracks into a filled matrix' do
      subject.add_step 1, :track_0_0
      subject.add_step 1, :track_0_1
      subject.add_step 2, :track_1_2
      subject.add_step 1, :track_0_3
      subject.add_step 3, :track_2_4

      expect(subject.tracks.to_a).to eq(
        [
          [nil, nil, nil, nil, nil],
          [:track_0_0, :track_0_1, nil, :track_0_3, nil],
          [nil, nil, :track_1_2, nil, nil],
          [nil, nil, nil, nil, :track_2_4]
        ]
      )
    end

    it 'does not allow steps to be added in noop_track' do
      expect { subject.add_step(0, :method) }.to raise_error('Invalid track `0`, must be a positive integer')
    end
  end

  context '#successor_track' do
    before do
      subject.tracks :track1, :track2, :track3
      subject.add_step :track1, :method1
      subject.add_step :track2, :method2
      subject.add_step :track3, :method3
    end

    it 'returns the identifier for the track one index higher' do
      expect(subject.successor_track(1)).to eq(2)
      expect(subject.successor_track(2)).to eq(3)
    end

    it 'returns nil if there are no successor track' do
      expect(subject.successor_track(3)).to eq(nil)
    end

    it 'raises an error if the index given is invalid' do
      expect { subject.successor_track(0) }.to raise_error
    end

    it 'can find successor track either by index or identifier' do
      expect(subject.successor_track(:track1)).to eq(:track2)
      expect(subject.successor_track(:track2)).to eq(:track3)
      expect(subject.successor_track(:track3)).to eq(nil)
    end
  end
end
