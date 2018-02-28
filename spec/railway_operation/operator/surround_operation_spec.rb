# frozen_string_literal: true

require 'spec_helper'

class SampleLogger
  extend FakeLogger

  def self.record
    log(0) << 'Before'
    yield
    log(0) << 'After'
  end
end

# This surround declaration below effectively results in
# the following surround structure
#
#  Surround#surround1 do
#    Surround#surround2 do
#      SampleLogger.record do
#        "block surround" do
#          run_steps
#        end
#      end
#    end
#  end
class Surround
  extend FakeLogger
  include RailwayOperation::Operator

  surround_operation :surround1
  surround_operation :surround2
  surround_operation [SampleLogger, :record]
  surround_operation do |operation| # This is a block surround
    log_from_block('Before Block Surround')
    operation.call
    log_from_block('After Block Surround')
  end

  add_step 0, :step1
  add_step 0, :step2
  add_step 0, :step3

  def self.log_from_block(message)
    log(3) << message
  end

  def surround1
    self.class.log(1) << 'Surround 1 Before'
    yield
    self.class.log(1) << 'Surround 1 After'
  end

  def surround2
    self.class.log(2) << 'Surround 2 Before'
    yield
    self.class.log(2) << 'Surround 2 After'
  end

  def step1(argument)
    argument[:step1] = true
  end

  def step2(argument)
    argument[:step2] = true
  end

  def step3(argument)
    argument[:step3] = true
  end
end

describe 'surround operation RailwayOperation::Operator' do
  context 'operation' do
    let!(:result) { Surround.run({}) }
    after(:each) do
      Surround.clear_log
      SampleLogger.clear_log
    end

    it 'executes steps' do
      expect(result).to eq(
        step1: true,
        step2: true,
        step3: true
      )
    end

    context 'instance method surrounds' do
      it 'surrounds operation with speficied instance method' do
        expect(Surround.log(1)).to eq(['Surround 1 Before', 'Surround 1 After'])
      end

      it 'surrounds operation can be nested' do
        expect(Surround.log(2)).to eq(['Surround 2 Before', 'Surround 2 After'])
      end
    end

    context 'arbitrary class method surrounds' do
      it { expect(SampleLogger.log(0)).to eq(%w[Before After]) }
    end

    context 'block surrounds' do
      it {
        expect(Surround.log(3)).to eq(
          ['Before Block Surround', 'After Block Surround']
        )
      }
    end
  end
end
