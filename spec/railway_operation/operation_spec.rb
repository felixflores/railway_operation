# frozen_string_literal: true

require 'spec_helper'

class DeclaringTracks
  include RailwayOperation::Operator

  add_step 0, :track_0_0
  add_step 0, :track_0_1, success: 2
  add_step 1, :track_1_2, failure: 1
  add_step 0, :track_0_3, success: 4
  add_step 2, :track_2_4
end

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

