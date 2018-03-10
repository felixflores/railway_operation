# frozen_string_literal: true

require 'spec_helper'

class SurroundSteps < InfiniteSteps
  extend FakeLogger
  step_surrounds[0] << :surround0
  step_surrounds['*'] << :surround1
  step_surrounds[2] << :surround2

  add_step 0, :method1
  add_step 0, :method2
  add_step 1, :method3
  add_step 0, :method4
  add_step 1, :method5
  add_step 0, :method6, success: 2
  add_step 2, :method7

  def surround0(_argument, arguments:, **, &block)
    log_surround(0, arguments, &block)
  end

  def surround1(_argument, arguments:, **, &block)
    log_surround(1, arguments, &block)
  end

  def surround2(_argument, arguments:, **, &block)
    log_surround(2, arguments, &block)
  end

  private

  def log_surround(index, arguments)
    step = arguments.length - 1

    self.class.log(index) << "step #{step} before"
    yield
    self.class.log(index) << "step #{step} after"
  end
end

describe 'surround step RailwayOperation::Operator' do
  before { SurroundSteps.run({}) }
  after { SurroundSteps.clear_log }

  it 'surrounds the 0th index track explicitly' do
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

  it 'surrounds steps could be declared with a wild card' do
    expect(SurroundSteps.log(1)).to eq(
      [
        'step 0 before', 'step 0 after',
        'step 1 before', 'step 1 after',
        'step 3 before', 'step 3 after',
        'step 5 before', 'step 5 after',
        'step 6 before', 'step 6 after'
      ]
    )
  end
end
