# frozen_string_literal: true

require 'spec_helper'

module Readme
  class FailingStep
    include RailwayOperation::Operator
    class MyError < StandardError; end

    fails_step << MyError

    add_step 0, :first_method
    add_step 0, :another_method
    add_step 0, :final_method
    add_step 1, :log_error

    def initialize(someone = 'someone')
      @someone = someone
    end

    def first_method(argument, **info)
      argument << "Hello #{@someone}, from first_method."
      [argument, info]
    end

    def another_method(argument, **info)
      argument << 'Hello from another_method.'
      [argument, info]
    end

    def final_method(argument, **)
      argument << 'Hello from final_method.'
      raise MyError
    end

    def log_error(argument, error:, **info)
      argument << "Error #{error.class}"
      [argument, info]
    end
  end
end

describe Readme::FailingStep do
  let(:argument) { [] }
  it 'executes methods in the order they are specified' do
    result, _info = described_class.run(argument)

    expect(result).to eq(
      [
        'Hello someone, from first_method.',
        'Hello from another_method.',
        'Error Readme::FailingStep::MyError'
      ]
    )
  end
end

