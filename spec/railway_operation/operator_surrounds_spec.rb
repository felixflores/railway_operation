# frozen_string_literal: true

require 'spec_helper'

class FakeLogger
  def log
    @data ||= []
    @data << 'Before Log'
    yield
    @data << 'After Log'
  end
end

class Surround < InfiniteSteps
  surround_operation :method
  surround_operation do |steps|
    FakeLogger.log(&steps)
  end

  track 0, :step1
  track 0, :step2
  track 0, :step3

  def self.instance_surround_log
    @instance_surround ||= []
    @instance_surround
  end

  def self.clear_instance_surround_log
    @instance_surround = []
  end

  def method
    self.class.instance_surround_log << 'Before'
    result = yield
    self.class.instance_surround_log << 'After'

    result
  end
end

describe 'surround RailwayOperation::Operator' do
  context 'operation' do
    let!(:result) { Surround.run({}) }
    after(:each) { Surround.clear_instance_surround_log }

    it 'executes steps' do
      expect(result['value']).to eq(%i[step1 step2 step3])
    end

    it 'surrounds operation with speficied instance method' do
      expect(Surround.instance_surround_log).to eq(%w[Before After])
    end
  end
end
