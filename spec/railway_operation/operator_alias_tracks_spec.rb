# frozen_string_literal: true

require 'spec_helper'

class AliasedTracks < InfiniteSteps
  alias_tracks alias1: 0, 'alias2' => 2, alias3: 1

  track :alias1, :step1, success: 'alias2'
  track 'alias2', :step2, success: :alias3
  track :alias3, :step3
end

describe 'alias step RailwayOperation::Operator' do
  it 'resolve tracks using alias' do
    result = AliasedTracks.run({})
    expect(result['value']).to eq(%i[step1 step2 step3])
  end
end
