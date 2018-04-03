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
    result, _info = Readme::Example2_1.run([])
    expect(result).to eq([1, 2])
  end
end
