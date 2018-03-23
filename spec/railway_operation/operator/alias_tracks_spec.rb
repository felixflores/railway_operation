# frozen_string_literal: true

require 'spec_helper'

class AliasedTracks < InfiniteSteps
  operation do |o|
    o.tracks :alias1, 'alias2', :alias3

    o.add_step :alias1, :step1
    o.add_step 'alias2', :step2
    o.add_step :alias3, :step3
  end
end

describe 'alias step RailwayOperation' do
  it 'resolves track aliases' do
    result1, _info = AliasedTracks.run({})
    expect(result1['value']).to eq([:step1])

    result2, _info = AliasedTracks.run({}, track_identifier: 'alias2')
    expect(result2['value']).to eq([:step2])

    result3, _info = AliasedTracks.run({}, track_identifier: :alias3)
    expect(result3['value']).to eq([:step3])
  end
end
