# frozen_string_literal: true

require 'spec_helper'

module Readme
  class Example3
    include RailwayOperation

    operation do |o|
      o.strategy(*Strategy.standard)

      o.add_step :normal, :method_1
      o.add_step :normal, :method_2
      o.add_step :error_track, :method_3
      o.add_step :error_track, :method_4
    end

    def initialize(someone = 'someone')
      @someone = someone
    end

    def method_1(argument, **)
      argument << 1
    end

    def method_2(argument, execution:, **)
      argument << 2
      execution.add_error(1)

      argument
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
  it 'uses capture strategy' do
    result, info = Readme::Example3.run([])

    expect(result).to eq([1, 2, 3, 4])
    expect(info.execution).to_not be_success

    expect(info.display.to_s).to eq(
      "+---+-------------+---------+----------+--------+\n"\
      "|                   Execution                   |\n"\
      "+---+-------------+---------+----------+--------+\n"\
      "|   | Track       | Success | Method   | Errors |\n"\
      "+---+-------------+---------+----------+--------+\n"\
      "| 0 | normal      | true    | method_1 | []     |\n"\
      "| 1 | normal      | false   | method_2 | [1]    |\n"\
      "| 2 | error_track | true    | method_3 | []     |\n"\
      "| 3 | error_track | true    | method_4 | []     |\n"\
      '+---+-------------+---------+----------+--------+'
    )
  end
end
