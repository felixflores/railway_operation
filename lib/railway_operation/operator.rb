# frozen_string_literal: true

require 'deep_clone'

module RailwayOperation
  # When RailwayOperation::Operator is include into any Ruby object
  # it extends that ruby class with the necessary methods to allow
  # objects to conform to the railway oriented convention.
  # See https://vimeo.com/97344498 for a high level overview
  module Operator
    class FailStep < StandardError; end
    class FailOperation < StandardError; end

    class HaltOperation < StandardError
      attr_reader :argument

      def initialize(argument)
        @argument = argument
      end
    end

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
                     :fails_operation,
                     :fails_step,
                     :nest,
                     :operation_surrounds,
                     :step_surrounds,
                     :tracks

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
    # This method is intended to run the default operation. Although it's
    # possible to invoke ohter operations of the class the method missing
    # approach is preffered (ie run_<operation_name>)
    module InstanceMethods
      include DynamicRun
      include Surround

      def run(argument, operation: :default, track_identifier: 0, step_index: 0)
        op = operation_with_defaults!(self.class.operation(operation))

        wrap(with: op.operation_surrounds) do
          run_steps(
            argument,
            Logger.new({ operation: op }),
            operation: op,
            track_identifier: track_identifier,
            step_index: step_index
          )
        end
      end

      def run_step(step_definition = nil, argument:, info:, surrounds: [])
        return argument unless step_definition

        pass_through = [DeepClone.clone(argument), info]

        info.current_step[:noop] = false
        wrap(with: surrounds, pass_through: pass_through) do |arg, inf|
          case step_definition[:method]
          when Symbol
            public_send(step_definition[:method], arg, inf)
          when Array
            step_definition[:method][0].send(step_definition[:method][1], arg, inf)
          else
            step_definition[:method].call(arg, inf)
          end
        end
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

      def run_steps(argument, info, track_identifier:, step_index:, operation:)
        info.execution << {
          track_identifier: track_identifier,
          step_index: step_index,
          argument: argument,
          noop: true
        }

        return [argument, info] if step_index > operation.last_step_index

        # We memoize the version of the argument which was passed
        # to run_steps at the first iteration of the recursion
        # this allows us to return it in case the the operation fails
        @original_argument ||= argument

        step_definition = operation[track_identifier, step_index]

        begin
          new_argument = run_step(
            step_definition,
            surrounds: operation.step_surrounds[track_identifier] + operation.step_surrounds['*'],
            argument: argument,
            info: info
          )

          run_steps(
            new_argument || argument,
            info,
            operation: operation,
            track_identifier: step_definition && step_definition[:success] || track_identifier,
            step_index: step_index + 1
          )
        rescue HaltOperation => e
          info.current_step[:error] = e
          info.current_step[:halted] = true
          [e.argument, info]
        rescue => e
          info.current_step[:error] = e
          info.current_step[:failed] = true

          if (operation.fails_step + [FailStep]).include?(e.class)
            run_steps(
              argument,
              info,
              operation: operation,
              track_identifier: step_definition[:failure] || operation.successor_track(track_identifier),
              step_index: step_index + 1
            )
          elsif (operation.fails_operation + [FailOperation]).include?(e.class)
            info.current_step[:failed_operation] = true
            [@original_argument, info]
          else
            raise e
          end
        end
      end

      def fail_step!
        raise FailStep
      end

      def fail_operation!
        raise FailOperation
      end

      def halt_operation!(argument)
        raise HaltOperation.new(argument)
      end
    end
  end
end
