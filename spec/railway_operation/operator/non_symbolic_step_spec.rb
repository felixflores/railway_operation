# frozen_string_literal: true

require 'spec_helper'

class AClass
  def self.call(argument, **_info)
    argument[:in_class_call] = true
    argument
  end

  def self.other(argument, **_info)
    argument[:in_class_other] = true
    argument
  end
end

class POROClass
  include RailwayOperation::Operator

  add_step 0, :step1
  add_step 0, AClass
  add_step 0, [AClass, :other]
  add_step(
    0,
    lambda do |argument, **_info|
      argument[:in_lambda] = true
      argument
    end
  )

  add_step(0) do |argument, **_info|
    argument[:in_block] = true
    argument
  end

  def step1(argument, **_info)
    argument[:in_normal_step] = true
    argument
  end
end

describe 'lambda step RailwayOperation::Operator' do
  it 'passes argument to lambda and class steps' do
    argument = { original: true }

    new_argument = argument.merge(
      in_lambda: true,
      in_class_call: true,
      in_class_other: true,
      in_normal_step: true,
      in_block: true
    )

    result, _info = POROClass.run(argument)
    expect(result).to eq(new_argument)
  end
end

