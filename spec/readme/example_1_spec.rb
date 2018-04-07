# frozen_string_literal: true

require 'spec_helper'

module Readme
  class Example1
    include RailwayOperation

    operation do |o|
      o.add_step 1, :first_method
      o.add_step 1, :another_method
      o.add_step 1, :final_method
    end

    def initialize(someone = 'someone')
      @someone = someone
    end

    def first_method(argument, **)
      argument << "Hello #{@someone}, from first_method."
    end

    def another_method(argument, **)
      argument << 'Hello from another_method.'
    end

    def final_method(argument, **)
      argument << 'Hello from final_method.'
    end
  end
end

describe Readme::Example1 do
  let(:argument) { [] }

  it 'executes methods in the order they are specified' do
    result, info = described_class.run(argument)

    expect(result).to eq(
      [
        'Hello someone, from first_method.',
        'Hello from another_method.',
        'Hello from final_method.'
      ]
    )

    expect(info.execution.all?(&:completed?)).to eq(true)
    expect(info.execution).to be_success
    expect(info.execution).to_not be_failed
    expect(info.execution.display).to eq(
      "+---+-------+---------+----------------+--------+\n"\
      "|                   Execution                   |\n"\
      "+---+-------+---------+----------------+--------+\n"\
      "|   | Track | Success | Method         | Errors |\n"\
      "+---+-------+---------+----------------+--------+\n"\
      "| 0 |       | true    | first_method   | []     |\n"\
      "| 1 |       | true    | another_method | []     |\n"\
      "| 2 |       | true    | final_method   | []     |\n"\
      '+---+-------+---------+----------------+--------+'
    )
  end

  it 'executes operation with the initialized parameter' do
    result, _info = described_class.new('Felix').run(argument)

    expect(result).to eq(
      [
        'Hello Felix, from first_method.',
        'Hello from another_method.',
        'Hello from final_method.'
      ]
    )
  end
end
