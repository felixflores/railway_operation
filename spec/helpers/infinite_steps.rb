# frozen_string_literal: true

require 'railway_operation'

class InfiniteSteps
  include RailwayOperation::Operator

  def method_missing(method, *args, **info, &block)
    return super unless method.match?(/step|method|fail/)

    argument = args.first
    argument['value'] ||= []
    argument['value'] << method

    argument
  end

  def respond_to_missing?(method, *_args)
    method.match?(/step|method|fail/)
  end
end
