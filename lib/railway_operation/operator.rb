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
    class HaltStep < StandardError; end
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

      def respond_to_missing?(method_name, _include_private = false)
        method_name.match(CAPTURE_OPERATION_NAME)
      end

      def method_missing(method_name, argument, **opts)
        operation = method_name.match(CAPTURE_OPERATION_NAME)[:operation]

        if operation
          run(argument, operation: operation, **opts)
        else
          super
        end
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

      def operation(op)
        @operations ||= {}

        the_op = if op.is_a?(Operation)
                   op
                 else
                   @operations[op.to_sym] ||= Operation.new(op.to_sym)
                 end

        # See operation/nested_operation_spec.rb for details for block syntax
        block_given? ? yield(the_op) : the_op
      end

      alias get_operation operation
      def add_step(*args, operation: nil, **info, &block)
        if operation.is_a?(Operation)
          operation.add_step(*args, **info, &block)
        else
          get_operation(operation || :default)
            .add_step(*args, **info, &block)
        end
      end

      def tracks
        operation(:default).tracks
      end

      def alias_tracks(mapping = {})
        operation(:default).alias_tracks(mapping)
      end

      def nest(*args)
        operation(:default).nest(*args)
      end

      def surround_operation(method = nil, &block)
        operation(:default).surrounds << (method || block)
      end

      def surround_steps(on_track: 0, with:)
        operation(:default).surround_steps(on_track: on_track, with: with)
      end

      def fails_step(*exceptions)
        operation(:default).fails_step(*exceptions)
      end

      def run(argument, **opts)
        new.run(argument, operation: operation(:default), **opts)
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

      def run(argument, operation: :default, track_id: 0, step_index: 0)
        op = self.class.operation(operation)
        operation_defaults!(op)

        operation_surrounds(
          argument,
          operation: op,
          operation_surrounds: op.surrounds,
          track_id: track_id,
          step_index: step_index
        )
      end

      private

      def operation_defaults!(operation)
        default_operation = self.class.operation(:default)
        return unless default_operation

        if operation.fails_step.empty?
          operation.fails_step(*default_operation.fails_step)
        end

        %i[surrounds step_surrounds track_alias].each do |attr|
          if operation.send(attr).empty?
            operation.send("#{attr}=", default_operation.send(attr))
          end
        end
      end

      def operation_surrounds(
        argument,
        operation:,
        operation_surrounds:,
        track_id:,
        step_index:
      )
        first, *rest = operation_surrounds
        result = nil

        send_surround(first) do
          result = if rest.empty?
                     run_steps(
                       argument,
                       operation: operation,
                       track_index: operation.track_index(track_id),
                       step_index: step_index
                     )
                   else
                     operation_surrounds(
                       argument,
                       operation: operation,
                       operation_surrounds: rest,
                       track_id: track_id,
                       step_index: step_index
                     )
                   end
        end

        result
      end

      def run_steps(argument, track_index:, step_index:, operation:, **info)
        return argument if step_index > operation.last_step_index

        # We memoize the version of the argument which was passed
        # to run_steps at the first iteration of the recursion
        # this allows us to return it in case the the operation fails
        @original_argument ||= argument # see rescue FailOperation

        # We are doing the clone early so that the new_argument
        # could be mutated in context of the operation step,
        # SwitchTrack or HaltExecution and maintain the mutations
        # to the argument thus far
        new_argument = argument.clone
        step_definition = operation.fetch_track(track_index)[step_index]
        step_surrounds = if operation.step_surrounds.empty?
                           self.class.operation(:default).step_surrounds
                         else
                           operation.step_surrounds
                         end

        begin
          if step_definition
            # If a step definition is found, execute the step definition
            # note that new_argument is passed by reference, and is not
            # returned. Doing this allows us to halt the mid-step.
            run_step_with_surround(
              surrounds: step_surrounds[track_index],
              step_definition: step_definition,
              argument: new_argument,
              step_index: step_index,
              **info
            )

            # then pass the modified argument to the next step.
            run_steps(
              new_argument,
              operation: operation,
              track_index: step_definition[:success] || track_index,
              step_index: step_index + 1,
              **info
            )
          else
            # If there are no step definitions found for a given step
            # of a track, proceed to the next step without any modification
            # to the argument.
            run_steps(
              argument,
              operation: operation,
              track_index: track_index,
              step_index: step_index + 1,
              **info
            )
          end
        rescue HaltStep
          next_track_index = step_definition[:success] || track_index

          # When we halt a step, we preserve the changes to the argument so far
          # in that step, and proceed to the next step with the modified
          # argument.
          run_steps(
            new_argument,
            operation: operation,
            track_index: next_track_index,
            step_index: step_index + 1,
            **info
          )
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
          next_track_index = step_definition[:failure] || track_index + 1

          # When a step is failed we rollback any changes performed at that step
          # and continue execution to of the proceeding steps.
          run_steps(
            argument,
            operation: operation,
            track_index: next_track_index,
            step_index: step_index + 1,
            error: e,
            **info
          )
        end
      end

      def run_step_with_surround(
        surrounds:,
        step_definition:,
        argument:,
        step_index:,
        **info
      )
        first, *rest = surrounds

        result = nil

        send_surround(first, argument, step_index) do
          result = if rest.empty?
                     run_step(step_definition, argument, **info)
                   else
                     run_step_with_surround(
                       rest,
                       step_definition,
                       argument,
                       **info
                     )
                   end
        end

        [result, info]
      end

      def run_step(step_definition, argument, **info)
        if step_definition[:method].is_a?(Symbol)
          send(step_definition[:method], argument, **info)
        else
          step_definition[:method].call(argument, **info)
        end
      end

      def fail_step!
        raise FailStep
      end

      def fail_operation!
        raise FailOperation
      end

      def halt_step!
        raise HaltStep
      end

      def halt_operation!
        raise HaltOperation
      end

      def tracks
        self.class.tracks
      end

      def send_surround(surround_definition, *args)
        case surround_definition
        when Symbol
          send(surround_definition, *args) { yield }
        when Array
          surround_definition[0].send(surround_definition[1], *args) { yield }
        when Proc
          surround_definition.call(-> { yield }, *args)
        else
          yield
        end
      end
    end
  end
end
