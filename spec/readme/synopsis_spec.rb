# frozen_string_literal: true

require 'spec_helper'

module Readme
  class Synopsis
    include RailwayOperation::Operator

    add_step 0, :first_method
    add_step 0, :another_method
    add_step 0, :final_method

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

describe Readme::Synopsis do
  let(:argument) { [] }
  it 'executes methods in the order they are specified' do
    result = described_class.run(argument)

    expect(result).to eq(
      [
        'Hello someone, from first_method.',
        'Hello from another_method.',
        'Hello from final_method.'
      ]
    )
  end

  it 'executes operation with the initialized parameter' do
    result = described_class.new('Felix').run(argument)

    expect(result).to eq(
      [
        'Hello Felix, from first_method.',
        'Hello from another_method.',
        'Hello from final_method.'
      ]
    )
  end
end
