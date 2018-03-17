# frozen_string_literal: true

require 'deep_clone'

module RailwayOperation
  # When RailwayOperation::Operator is include into any Ruby object
  # it extends that ruby class with the necessary methods to allow
  # objects to conform to the railway oriented convention.
  # See https://vimeo.com/97344498 for a high level overview
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
      extend Forwardable

      def_delegators :default_operation,
                     :add_step,
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

      def run(argument, operation: :default, track_identifier: 1, step_index: 0, **info)
        op = operation_with_defaults!(self.class.operation(operation))
        wrap(with: op.operation_surrounds) do
          run_steps(
            argument,
            operation: op,
            track_identifier: track_identifier,
            step_index: step_index,
            **info
          )
        end
      end

      def run_step(argument, operation:, track_identifier:, step_index:, **info)
        info.merge!(operation: operation, track_identifier: track_identifier, step_index: step_index)

        Info.execution(info)[step_index] = {
          argument: argument,
          track_identifier: track_identifier,
          step_index: step_index,
          method: nil,
          noop: true
        }

        step_definition = operation[track_identifier, step_index]
        return [argument, info] unless step_definition

        surrounds = operation.step_surrounds[track_identifier] + operation.step_surrounds['*']
        pass_through = [DeepClone.clone(argument), info]

        Info.execution(info)[step_index].merge!(
          method: step_definition,
          noop: false
        )

        new_argument = wrap(with: surrounds, pass_through: pass_through) do |arg, inf|
          case step_definition
          when Symbol
            # add_step 1, :method
            public_send(step_definition, arg, inf)
          when Array
            # add_step 1, [MyClass, :method]
            step_definition[0].send(step_definition[1], arg, inf)
          else
            # add_step 1, ->(argument, info) { ... }
            step_definition.call(arg, inf)
          end
        end

        [new_argument, info]
      end

      private

      def operation_with_defaults!(operation)
        default_operation = self.class.default_operation
        return operation if operation == default_operation

        operation.operation_surrounds ||= default_operation.operation_surrounds
        operation.step_surrounds ||= default_operation.step_surrounds
        operation.track_alias ||= default_operation.track_alias
        operation.stepper_function(default_operation.stepper_function || DEFAULT_STRATEGY)

        operation
      end

      def run_steps(argument, operation:, track_identifier:, step_index:, **info)
        info.merge!(operation: operation, track_identifier: track_identifier, step_index: step_index)

        return [argument, info] if step_index > operation.last_step_index

        new_argument = new_info = nil
        vector = Stepper.step(operation.stepper_function || DEFAULT_STRATEGY, info) do
          new_argument, new_info = run_step(argument, info)
          Info.execution(new_info)[step_index][:succeeded] = true

          [new_argument, new_info]
        end

        run_steps(
          vector[:argument].((new_argument || argument), info),
          (new_info || info).merge(
            step_index: vector[:step_index].(new_info || info),
            track_identifier: vector[:track_identifier].(new_info || info)
          )
        )
      end
    end
  end
end
