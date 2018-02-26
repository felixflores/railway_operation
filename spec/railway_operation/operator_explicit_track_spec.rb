# frozen_string_literal: true

require 'spec_helper'

class ExplicitSuccessTrack < InfiniteSteps
  track 0, :step1
  track 0, :step2, success: 4
  track 4, :step3
  track 1, :step4
end

class DistantExplicitSuccessTrack < InfiniteSteps
  track 0, :step1
  track 0, :step2, success: 20
  track 2, :step3
  track 1, :step4
end

class ExplicitFailTrack < InfiniteSteps
  track 0, :step1
  track 0, :step2, failure: 2
  track 1, :skip3
  track 2, :step4

  def step2(_argument)
    fail_step!
  end
end

class DistantExplicitFailTrack < InfiniteSteps
  track 0, :step1
  track 0, :step2, failure: 20
  track 0, :skip3
  track 1, :skip4

  def step2(_argument)
    fail_step!
  end
end

describe 'explicit tracks RailwayOperation::Operator' do
  context 'explicit success track' do
    it 'switches to the specified track if the step succeeds' do
      result = ExplicitSuccessTrack.run({})
      expect(result['value']).to eq(%i[step1 step2 step3])
    end

    it 'switches to the specified distant track if the step succeeds' do
      result = DistantExplicitSuccessTrack.run({})
      expect(result['value']).to eq(%i[step1 step2])
    end
  end

  context 'explicit fail track' do
    it 'switches to the specified track if the step fail' do
      result = ExplicitFailTrack.run({})
      expect(result['value']).to eq(%i[step1 step4])
    end

    it 'switches to the specified distant track if the step fails' do
      result = DistantExplicitFailTrack.run({})
      expect(result['value']).to eq(%i[step1])
    end
  end
end
