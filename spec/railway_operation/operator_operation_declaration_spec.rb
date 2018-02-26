# frozen_string_literal: true

require 'spec_helper'

class Sample < InfiniteSteps
  operation(:variation1) do |o|
    o.track 0, :method3
    o.track 0, :method2
    o.track 0, :method1
  end

  track 0, :method2, operation: :variation2
  track 0, :method1, operation: :variation2
  track 0, :method3, operation: :variation2

  track 0, :method1
  track 0, :method2
  track 0, :method3
end

describe 'operation declaration RailwayOperation::Operator' do
  
end
