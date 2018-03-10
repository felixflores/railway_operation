# frozen_string_literal: true

require 'spec_helper'

class ExplicitSuccessTrack < InfiniteSteps
  add_step 0, :step1
  add_step 0, :step2, success: 4
  add_step 4, :step3
  add_step 1, :step4
end

class DistantExplicitSuccessTrack < InfiniteSteps
  add_step 0, :step1
  add_step 0, :step2, success: 20
  add_step 2, :step3
  add_step 1, :step4
end

class ExplicitFailTrack < InfiniteSteps
  add_step 0, :step1
  add_step 0, :step2, failure: 2
  add_step 1, :skip3
  add_step 2, :step4

  def step2(_argument, **)
    fail_step!
  end
end

class DistantExplicitFailTrack < InfiniteSteps
  add_step 0, :step1
  add_step 0, :step2, failure: 20
  add_step 0, :skip3
  add_step 1, :skip4

  def step2(_argument, **)
    fail_step!
  end
end

describe 'explicit tracks RailwayOperation::Operator' do
  context 'explicit success track' do
    it 'switches to the specified track if the step succeeds' do
      result, _info = ExplicitSuccessTrack.run({})
      expect(result['value']).to eq(%i[step1 step2 step3])
    end

    it 'switches to the specified distant track if the step succeeds' do
      result, _info = DistantExplicitSuccessTrack.run({})
      expect(result['value']).to eq(%i[step1 step2])
    end
  end

  context 'explicit fail track' do
    it 'switches to the specified track if the step fail' do
      result, _info = ExplicitFailTrack.run({})
      expect(result['value']).to eq(%i[step1 step4])
    end

    it 'switches to the specified distant track if the step fails' do
      result, _info = DistantExplicitFailTrack.run({})
      expect(result['value']).to eq(%i[step1])
    end
  end
end
