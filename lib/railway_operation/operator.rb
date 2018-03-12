# frozen_string_literal: true

require 'deep_clone'

module RailwayOperation
  # When RailwayOperation::Operator is include into any Ruby object
  # it extends that ruby class with the necessary methods to allow
  # objects to conform to the railway oriented convention.
  # See https://vimeo.com/97344498 for a high level overview
  module Operator
    def self.included(base)
      base.extend ClassMethods
      base.send :include, InstanceMethods
    end

    # The DynamicRun allows the module which includes it to have a method
    # with that is run_<something>.
    #
    # ex: run_variation1, run_something, run_my_operation_name
    module DynamicRun
      CAPTURE_OPERATION_NAME = /run_*(?<operation>\w*)/

      def respond_to_missing?(method, _include_private = false)
        method.match(CAPTURE_OPERATION_NAME)
      end

      def method_missing(method, *args, &block)
        return super unless method.match?(CAPTURE_OPERATION_NAME)

        operation = method.match(CAPTURE_OPERATION_NAME)[:operation]
        run(args[0], operation: operation, **(args[1] || {}))
      end
    end

    # The operator class method allows classes which include this module
    # to delegate actions to the default operation of the @operations
    # array.
    #
    # The default operation is a normal RailwayOperation::Operation classes
    # however it is used to store step declarations as well as other operation
    # attributes such as track_alias, fails_step, etc. If other operations of
    # the class do not declare values for these attributes, the values
    # assigned to the default operation is used.
    module ClassMethods
      include DynamicRun
      extend Forwardable

      def_delegators :default_operation,
                     :alias_tracks,
                     :nest,
                     :operation_surrounds,
                     :step_surrounds,
                     :stepper_function

      def operation(operation_or_name)
        @operations ||= {}

        name = Operation.format_name(operation_or_name)
        operation = @operations[name] ||= Operation.new(operation_or_name)

        # See operation/nested_operation_spec.rb for details for block syntax
        block_given? ? yield(operation) : operation
      end

      alias get_operation operation
      def add_step(*args, operation: nil, **options, &block)
        get_operation(operation || :default).add_step(*args, **options, &block)
      end

      def run(argument, operation: :default, **opts)
        new.run(argument, operation: operation, **opts)
      end

      def default_operation
        operation(:default)
      end
    end

    # The RailwayOperation::Operator instance methods exposes a single
    # method - RailwayOperation::Operator#run
    #
    # This method is intended to run thpe default operation. Although it's
    # possible to invoke ohter operations of the class the method missing
    # approach is preffered (ie run_<operation_name>)
    module InstanceMethods
      include DynamicRun
      include Surround

      def run(argument, operation: :default, track_identifier: 1, step_index: 0)
        op = operation_with_defaults!(self.class.operation(operation))

        wrap(with: op.operation_surrounds) do
          run_steps(
            argument,
            { operation: op },
            operation: op,
            track_identifier: track_identifier,
            step_index: step_index
          )
        end
      end

      def run_step(argument, operation:, track_identifier:, step_index:, info: {})
        log = Logger.new(info)

        log.execution << {
          track_identifier: track_identifier,
          step_index: step_index,
          argument: argument,
          noop: true
        }

        step_definition = operation[track_identifier, step_index]
        return [argument, log] unless step_definition

        surrounds = operation.step_surrounds[track_identifier] + operation.step_surrounds['*']
        log.current_step[:noop] = false

        new_argument = wrap(with: surrounds, pass_through: [DeepClone.clone(argument), log]) do |arg, inf|
          case step_definition[:method]
          when Symbol
            public_send(step_definition[:method], arg, inf)
          when Array
            step_definition[:method][0].send(step_definition[:method][1], arg, inf)
          else
            step_definition[:method].call(arg, inf)
          end
        end

        [new_argument, log]
      end

      private

      def operation_with_defaults!(operation)
        default_operation = self.class.default_operation
        return operation if operation == default_operation

        operation.fails_step ||= default_operation.fails_step
        operation.operation_surrounds ||= default_operation.operation_surrounds
        operation.step_surrounds ||= default_operation.step_surrounds
        operation.track_alias ||= operation.track_alias

        operation
      end

      def run_steps(argument, info, track_identifier: 1, step_index:, operation:)
        return [argument, info] if step_index > operation.last_step_index

        # We memoize original argument so that we can return the original
        # value if the operation is aborted
        @original_argument ||= argument

        new_argument = nil
        vector = Stepper.step(operation.stepper_function) do
          new_argument, info = run_step(
            argument,
            operation: operation,
            info: info,
            track_identifier: track_identifier,
            step_index: step_index
          )

          [new_argument, info]
        end

        run_steps(
          vector[:argument].(
            operation,
            argument: {
              original: @original_argument,
              before: argument,
              after: new_argument
            }
          ),
          info,
          operation: operation,
          step_index: vector[:step_index].(operation, step_index),
          track_identifier: vector[:track_identifier].(operation, track_identifier)
        )
      end
    end
  end
end
