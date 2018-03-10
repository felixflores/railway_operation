# frozen_string_literal: true

require 'railway_operation'

class InfiniteSteps
  include RailwayOperation::Operator

  def method_missing(method, *args, **info, &block)
    argument = args.first
    return super unless argument.is_a?(Hash)

    argument['value'] ||= []
    argument['value'] << method

    [argument, info]
  end

  def respond_to_missing?(*)
    true
  end
end
