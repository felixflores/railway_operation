# frozen_string_literal: true

require 'railway_operation/version'
require 'railway_operation/generic/ensured_access'
require 'railway_operation/generic/filled_matrix'
require 'railway_operation/generic/typed_array'
require 'railway_operation/stepper'
require 'railway_operation/strategy'
require 'railway_operation/surround'
require 'railway_operation/steps_array'
require 'railway_operation/operation'
require 'railway_operation/operator'
require 'railway_operation/formatter'
require 'railway_operation/info'

module RailwayOperation
  def self.included(base)
    base.extend Operator::ClassMethods
    base.send :include, Operator::InstanceMethods
  end
end
