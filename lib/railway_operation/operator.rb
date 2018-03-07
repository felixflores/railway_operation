# frozen_string_literal: true

module RailwayOperation
  # When RailwayOperation::Operator is include into any Ruby object
  # it extends that ruby class with the necessary methods to allow
  # objects to conform to the railway oriented convention.
  # See https://vimeo.com/97344498 for a high level overview
  #
  # Sample usage
  #
  # class SomeObject
  #   include RailwayOperation::Operator
  #
  #   track_alias process_1: 0, process_2: 1, process_3: 2
  #
  #   track :process_1, Something.new
  #   track :process_1, ValidateObject
  #   track :process_1, :a_method
  #   track :process_2, LogFailure
  #   track :process_1, :persist!
  #   track :process_1, LogSuccess
  # end
  #
  # SomeObject.run(my: 'values', in: 'the_hash')
  module Operator
    class FailStep < StandardError; end
    class HaltOperation < StandardError; end
    class FailOperation < StandardError; end

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
        return super unless respond_to_missing?(method)

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
                     :tracks,
                     :alias_tracks,
                     :nest,
                     :operation_surrounds,
                     :step_surrounds,
                     :fails_step

      def operation(op)
        @operations ||= {}

        the_op = if op.is_a?(Operation)
                   op
                 else
                   @operations[op.to_sym] ||= Operation.new(op)
                 end

        # See operation/nested_operation_spec.rb for details for block syntax
        block_given? ? yield(the_op) : the_op
      end

      alias get_operation operation
      def add_step(*args, operation: nil, **options, &block)
        if operation.is_a?(Operation)
          operation.add_step(*args, **options, &block)
        else
          get_operation(operation || :default)
            .add_step(*args, **options, &block)
        end
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
        result = nil
        result_info = {}

        wrap(with: op.operation_surrounds) do
          result, result_info = run_steps(
            argument,
            {},
            operation: op,
            track_identifier: track_identifier,
            step_index: step_index
          )
        end

        [result, result_info]
      end

      private

      def operation_with_defaults!(operation)
        default_operation = self.class.default_operation
        return operation if operation == default_operation || default_operation.nil?

        op = operation.clone

        op.fails_step(*default_operation.fails_step) if op.fails_step.empty?

        %i[operation_surrounds step_surrounds track_alias].each do |attr|
          if op.public_send(attr).empty?
            op.public_send("#{attr}=", default_operation.public_send(attr))
          end
        end

        op
      end

      def run_steps(argument, info, track_identifier:, step_index:, operation:)
        info[:arguments] ||= []
        info[:arguments] << argument

        return [argument, info] if step_index > operation.last_step_index

        # We memoize the version of the argument which was passed
        # to run_steps at the first iteration of the recursion
        # this allows us to return it in case the the operation fails
        @original_argument ||= argument.clone # see rescue FailOperation

        # We are doing the clone early so that the new_argument
        # could be mutated in context of the operation step,
        # SwitchTrack or HaltExecution and maintain the mutations
        # to the argument thus far
        new_argument = argument.clone
        step_definition = operation[track_identifier, step_index]

        begin
          if step_definition
            # If a step definition is found, execute the step definition
            # note that new_argument is passed by reference, and is not
            # returned. Doing this allows us to halt the mid-step.
            step_surrounds = operation.step_surrounds[track_identifier]
            step_surrounds += operation.step_surrounds['*']

            wrap(with: step_surrounds, pass_through: [new_argument, info]) do |wrapped_args, wrapped_info|
              new_argument, info = run_step(step_definition, wrapped_args, wrapped_info)
            end

            # then pass the modified argument to the next step.
            run_steps(
              new_argument,
              info,
              operation: operation,
              track_identifier: step_definition[:success] || track_identifier,
              step_index: step_index + 1
            )
          else
            # If there are no step definitions found for a given step
            # of a track, proceed to the next step without any modification
            # to the argument.
            run_steps(
              argument,
              info,
              operation: operation,
              track_identifier: track_identifier,
              step_index: step_index + 1
            )
          end
        rescue HaltOperation
          # This is the version of the argument after it was potentially
          # modified by run_steps. Halting preseverse modifications performed
          # to the argument up to the point it was halted.
          new_argument
        rescue FailOperation
          # this the value of the argument prior to it being passed to run_steps
          [@original_argument, info]
        rescue => e
          raise e unless (operation.fails_step + [FailStep]).include?(e.class)
          next_track_index = step_definition[:failure] || track_identifier + 1

          # When a step is failed we rollback any changes performed at that step
          # and continue execution to of the proceeding steps.
          info[:error] = e

          run_steps(
            argument,
            info,
            operation: operation,
            track_identifier: next_track_index,
            step_index: step_index + 1,
          )
        end
      end

      def run_step(step_definition, argument, info)
        if step_definition[:method].is_a?(Symbol)
          public_send(step_definition[:method], argument, info)
        else
          step_definition[:method].call(argument, info)
        end
      end

      def fail_step!
        raise FailStep
      end

      def fail_operation!
        raise FailOperation
      end

      def halt_operation!
        raise HaltOperation
      end
    end
  end
end
