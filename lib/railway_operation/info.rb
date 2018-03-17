# frozen_string_literal: true

module RailwayOperation
  # This is intended to extend the functionality of a normal
  # hash to make it easier to inspect the log
  class Info
    class << self
      def execution(info)
        info[:execution] ||= []
        info[:execution]
      end

      def first_step(info)
        execution(info).first
      end

      def last_step(info)
        execution(info).last
      end

      def last_step_succeeded?(info)
        !!last_step(info)[:succeeded]
      end

      def failed_steps(info)
        execution(info).select { |step| step[:failed] }
      end

      def failed?(info)
        execution(info).select { |step| step[:operation_failed] }
      end
    end
  end
end
