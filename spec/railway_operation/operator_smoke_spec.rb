# frozen_string_literal: true

require 'spec_helper'

class DeclaringTracks
  include RailwayOperation::Operator

  track 0, :track_0_0
  track 0, :track_0_1, success: 2
  track 1, :track_1_2, failure: 1
  track 0, :track_0_3, success: 4
  track 2, :track_2_4
end

class HappyPath < InfiniteSteps
  track 0, :step1
  track 0, :step2
  track 0, :step3
end

describe 'smoke test RailwayOperation::Operator' do
  context '.track' do
    let(:track0) do
      [
        { method: :track_0_0, success: nil, failure: nil },
        { method: :track_0_1, success: 2, failure: nil },
        nil,
        { method: :track_0_3, success: 4, failure: nil }
      ]
    end

    let(:track1) do
      [nil, nil, { method: :track_1_2, success: nil, failure: 1 }]
    end

    let(:track2) do
      [nil, nil, nil, nil, { method: :track_2_4, success: nil, failure: nil }]
    end

    it 'allows tracks to be declare' do
      expect(DeclaringTracks.tracks).to eq([track0, track1, track2])
    end
  end
  describe '.run' do
    it 'executes the steps in the operation' do
      result = HappyPath.run
      expect(result['value']).to eq(%i[step1 step2 step3])
    end

    it 'does not mutate arguments passed to the operation' do
      argument = { 'original_value' => "don't change" }
      result = HappyPath.run(argument)

      expect(argument).to eq('original_value' => "don't change")
      expect(result).to eq('original_value' => "don't change", 'value' => %i[step1 step2 step3])
    end
  end
end
