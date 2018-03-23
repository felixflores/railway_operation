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
  include RailwayOperation

  operation do |o|
    o.add_step 1, :step1
    o.add_step 1, AClass
    o.add_step 1, [AClass, :other]
    o.add_step(
      1,
      lambda do |argument, **_info|
        argument[:in_lambda] = true
        argument
      end
    )

    o.add_step(1) do |argument, **_info|
      argument[:in_block] = true
      argument
    end
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
