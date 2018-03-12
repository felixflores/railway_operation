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

    def first_method(argument, **_info)
      argument << "Hello #{@someone}, from first_method."
    end

    def another_method(argument, **_info)
      argument << 'Hello from another_method.'
      raise MyError
    end

    def final_method(argument, **)
      argument << 'Hello from final_method.'
    end

    def log_error(argument, info)
      error = info.failed_steps.last
      argument << "Error #{error[:error].class}"
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
        'Error Readme::FailingStep::MyError'
      ]
    )
  end
end
