# frozen_string_literal: true

require 'spec_helper'

class AClass
  def self.call(argument)
    argument[:in_class_call] = true
  end
end

class POROClass
  include RailwayOperation::Operator

  add_step 0, :step1
  add_step 0, AClass
  add_step 0, ->(argument) { argument[:in_lambda] = true }
  add_step 0 do |argument|
    argument[:in_block] = true
  end

  def step1(argument)
    argument[:in_normal_step] = true
  end
end

describe 'lambda step RailwayOperation::Operator' do
  it 'passes argument to lambda and class steps' do
    argument = { original: true }

    new_argument = argument.merge(
      in_lambda: true,
      in_class_call: true,
      in_normal_step: true,
      in_block: true
    )

    expect(POROClass.run(argument)).to eq(new_argument)
  end
end

