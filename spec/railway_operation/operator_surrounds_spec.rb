# frozen_string_literal: true

require 'spec_helper'

class FakeLogger
  def self.record
    log << 'Before'
    yield
    log << 'After'
  end

  def self.log
    @log ||= []
  end

  def self.clear_log
    @log = []
  end
end

# This surround declaration below effectively results in
# the following surround structure
#
#  Surround#surround1 do
#    Surround#surround2 do
#      FakeLogger.record do
#        run_steps
#      end
#    end
#  end
class Surround < InfiniteSteps
  surround_operation :surround1
  surround_operation :surround2
  surround_operation [FakeLogger, :record]
  # surround_operation do |operation|
  #   FakeLogger.log('Before Log')
  #   operation.run
  #   FakeLogger.log('After Log')
  # end

  track 0, :step1
  track 0, :step2
  track 0, :step3

  def self.log1
    @log1 ||= []
  end

  def self.clear_log1
    @log1 = []
  end

  def self.log2
    @log2 ||= []
  end

  def self.clear_log2
    @log2 = []
  end

  def surround1
    self.class.log1 << 'Surround 1 Before'
    yield
    self.class.log1 << 'Surround 1 After'
  end

  def surround2
    self.class.log2 << 'Surround 2 Before'
    yield
    self.class.log2 << 'Surround 2 After'
  end
end

describe 'surround RailwayOperation::Operator' do
  context 'operation' do
    let!(:result) { Surround.run({}) }
    after(:each) do
      Surround.clear_log1
      Surround.clear_log2
      FakeLogger.clear_log
    end

    it 'executes steps' do
      expect(result['value']).to eq(%i[step1 step2 step3])
    end

    context 'instance method surrounds' do
      it 'surrounds operation with speficied instance method' do
        expect(Surround.log1).to eq(['Surround 1 Before', 'Surround 1 After'])
      end

      it 'surrounds operation can be nested' do
        expect(Surround.log2).to eq(['Surround 2 Before', 'Surround 2 After'])
      end
    end

    context 'arbitrary class method surrounds' do
      it 'is allowed to be declare' do
        expect(FakeLogger.log).to eq(['Before', 'After'])
      end
    end

    context 'block surrounds'
  end
end
