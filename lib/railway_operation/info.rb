# frozen_string_literal: true

module RailwayOperation
  class Info < DelegateClass(Hash)
    def new(maybe_obj)
      maybe_obj.is_a?(Info) ? maybe_obj : super
    end

    def initialize(operation:, **info)
      super info.merge(operation: operation)
    end

    def operation
      self[:operation]
    end

    def operation=(op)
      self[:operation] = op
    end

    def execution
      self[:execution] = Execution.new(self[:execution] || [])
    end
  end

  # This is intended to extend the functionality of a normal
  # hash to make it easier to inspect the log
  class Execution < DelegateClass(Array)
    def new(maybe_obj)
      maybe_obj.is_a?(Execution) ? maybe_obj : super
    end

    def initialize(obj = [])
      super
    end

    def <<(value)
      super Step.new(value)
    end

    def []=(index, value)
      super index, Step.new(value)
    end

    def first_step
      first
    end

    def last_step
      last
    end

    def add_error(error)
      last.add_error(error)
    end

    def errored?
      any?(&:errored?)
    end

    def success?
      all?(&:success?)
    end

    def failed?
      !success?
    end

    def completed?
      all?(&:completed?)
    end

    def add_step(argument:, track_identifier:, step_index:)
      self << {
        argument: argument,
        track_identifier: track_identifier,
        step_index: step_index
      }

      last
    end

    def display
      table = Terminal::Table.new
      table.title = 'Execution'
      table.headings = ['', 'Track', 'Success', 'Method', 'Errors']
      table.rows = self.map do |s|
        [
          s[:step_index],
          s[:track_identifier],
          s.success?,
          s[:noop] ? '--' : (s[:method].is_a?(Proc) ? 'Proc' : s[:method]),
          s[:errors]
        ]
      end

      table.to_s
    end
  end

  class Step < DelegateClass(Hash)
    def new(maybe_obj)
      maybe_obj.is_a?(Step) ? maybe_obj : super
    end

    def initialize(obj = {})
      super
    end

    def started_at
      self[:started_at]
    end

    def ended_at
      self[:ended_at]
    end

    def completed_at
      ended_at
    end

    def started?
      self[:started_at]
    end

    def completed?
      started? && self[:ended_at]
    end

    def success?
      errors.empty? && !self[:failed]
    end

    def errored?
      !errors.empty?
    end

    def failed?
      !!self[:failed]
    end

    def noop?
      self[:noop]
    end

    def start!
      self[:started_at] = timestamp
    end

    def end!
      raise 'cannot complete step that has not yet started' unless started?
      self[:ended_at] = timestamp
    end

    def fail!(error)
      self[:failed_at] = timestamp
      add_error(error)
    end

    def add_error(error)
      errors << error if error
    end

    def noop!
      self[:started_at] = self[:ended_at] = timestamp
      self[:method] = nil
      self[:noop] = true
    end

    def errors
      self[:errors] ||= []
      self[:errors]
    end

    def track_identifier
      self[:track_identifier]
    end

    def step_index
      self[:step_index]
    end

    def timestamp
      Time.respond_to?(:current) ? Time.current : Time.now
    end
  end
end
