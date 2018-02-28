# frozen_string_literal: true

require 'spec_helper'

class SurroundSteps < InfiniteSteps
  extend FakeLogger
  surround_steps with: :surround0
  surround_steps on_track: 2, with: :surround2

  add_step 0, :method1
  add_step 0, :method2
  add_step 1, :method3
  add_step 0, :method4
  add_step 1, :method5
  add_step 0, :method6, success: 2
  add_step 2, :method7

  def surround0(_argument, index)
    self.class.log(0) << "step #{index} before"
    yield
    self.class.log(0) << "step #{index} after"
  end

  def surround2(_argument, index)
    self.class.log(2) << "step #{index} before"
    yield
    self.class.log(2) << "step #{index} after"
  end
end

describe 'surround step RailwayOperation::Operator' do
  before { SurroundSteps.run({}) }
  after { SurroundSteps.clear_log }

  it 'surrounds the 0th index track implicitly' do
    expect(SurroundSteps.log(0)).to eq(
      [
        'step 0 before', 'step 0 after',
        'step 1 before', 'step 1 after',
        'step 3 before', 'step 3 after',
        'step 5 before', 'step 5 after'
      ]
    )
  end

  it 'surrounds steps on track explicitly' do
    expect(SurroundSteps.log(2)).to eq(['step 6 before', 'step 6 after'])
  end
end
