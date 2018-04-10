# frozen_string_literal: true

require 'deep_clone'

module RailwayOperation
  module Operator
    DEFAULT_STRATEGY = Strategy::DEFAULT

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

      def operation(operation_or_name = :default)
        @operations ||= {}

        name = Operation.format_name(operation_or_name)
        op = @operations[name] ||= Operation.new(operation_or_name)

        # See operation/nested_operation_spec.rb for details for block syntax

        block_given? ? yield(op) : op
      end

      def run(argument, operation: :default, **opts)
        new.run(argument, operation: operation, **opts)
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

      def run(argument, operation: :default, track_identifier: 1, step_index: 0, **info)
        op = self.class.operation(operation)

        wrap(*op.operation_surrounds) do
          _run(
            argument,
            Info.new(operation: op, **info),
            track_identifier: op.track_identifier(track_identifier),
            step_index: step_index
          )
        end
      end

      def run_step(argument, operation: :default, track_identifier:, step_index:, **info)
        op = self.class.operation(operation)

        new_info = Info.new(operation: op, **info)
        new_info.execution.add_step(
          argument: argument,
          track_identifier: track_identifier,
          step_index: step_index
        )

        _run_step(argument, new_info)
      end

      private

      def _run_step(argument, info)
        step = info.execution.last

        step_definition = info.operation[step.track_identifier, step.step_index]
        unless step_definition
          step.noop!
          return [argument, info]
        end

        step.start!

        surrounds = info.operation.step_surrounds[step.track_identifier] + info.operation.step_surrounds['*']
        wrap_arguments = [DeepClone.clone(argument), info]

        step[:method] = step_definition
        step[:noop] = false

        step[:argument] = wrap(*surrounds, arguments: wrap_arguments) do
          case step_definition
          when Symbol
            # add_step 1, :method
            public_send(step_definition, *wrap_arguments)
          when Array
            # add_step 1, [MyClass, :method]
            step_definition[0].send(step_definition[1], *wrap_arguments)
          else
            # add_step 1, ->(argument, info) { ... }
            step_definition.call(*wrap_arguments)
          end
        end

        step.end!

        [step[:argument], info]
      end

      def _run(argument, info, track_identifier:, step_index:)
        return [argument, info] if step_index > info.operation.last_step_index

        info.execution.add_step(
          argument: argument,
          track_identifier: track_identifier,
          step_index: step_index
        )

        stepper_fn = info.operation.stepper_function || DEFAULT_STRATEGY

        vector = Stepper.step(stepper_fn, info) do
          _run_step(argument, info)
        end

        _run(
          vector[:argument].(info),
          info,
          track_identifier: vector[:track_identifier].(info),
          step_index: vector[:step_index].(info)
        )
      end
    end
  end
end
