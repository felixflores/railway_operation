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

    it 'returns the name in underscore format' do
      expect(subject.name).to eq(:operation_sample)
      expect(operation1.name).to eq(:operation_name)
      expect(operation2.name).to eq(:operation_name)
      expect(operation3.name).to eq(:operation_name)
      expect(operation4.name).to eq(:operation_name)
    end
  end

  context '#operation_surrounds' do
    it 'allows symbols to be pushed'
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
