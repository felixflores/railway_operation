# frozen_string_literal: true

module RailwayOperation
  # This is intended to extend  the functionality of a normal
  # hash to make it easier to inspect the log
  class Logger < Delegator
    def initialize(info = {})
      raise 'Must be a kind of hash' unless info.is_a?(Hash)
      @info = info
    end

    def __setobj__(info)
      @info = info
    end

    def __getobj__
      @info
    end

    def execution
      @info[:execution] ||= []
      @info[:execution]
    end

    def current_step
      @info[:execution].last
    end

    def failed_steps
      execution.select { |step| step[:failed] }
    end

    def failed?
      execution.select { |step| step[:operation_failed] }
    end
  end
end
