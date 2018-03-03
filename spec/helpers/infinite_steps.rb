# frozen_string_literal: true

require 'railway_operation'

class InfiniteSteps
  include RailwayOperation::Operator

  def method_missing(method, argument, **)
    argument['value'] ||= []
    argument['value'] << method
  end

  def respond_to_missing?(*)
    true
  end
end
