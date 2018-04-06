# frozen_string_literal: true

require 'spec_helper'

module Readme
  class Example2_1
    include RailwayOperation

    operation do |o|
      o.add_step 1, :method_1
      o.add_step 1, :method_2
      o.add_step 2, :method_3
      o.add_step 2, :method_4
    end

    def initialize(someone = 'someone')
      @someone = someone
    end

    def method_1(argument, **)
      argument << 1
    end

    def method_2(argument, **)
      argument << 2
    end

    def method_3(argument, **)
      argument << 3
    end

    def method_4(argument, **)
      argument << 4
    end
  end
end

describe 'Normal execution' do
  it 'runs on the normal track' do
    result, info = Readme::Example2_1.run([])

    expect(result).to eq([1, 2])
    expect(info.execution.display).to eq(
      "+---+-------+---------+----------+--------+\n"\
      "|                Execution                |\n"\
      "+---+-------+---------+----------+--------+\n"\
      "|   | Track | Success | Method   | Errors |\n"\
      "+---+-------+---------+----------+--------+\n"\
      "| 0 |       | true    | method_1 | []     |\n"\
      "| 1 |       | true    | method_2 | []     |\n"\
      "| 2 |       | true    | --       | []     |\n"\
      "| 3 |       | true    | --       | []     |\n"\
      '+---+-------+---------+----------+--------+'
    )
  end
end
