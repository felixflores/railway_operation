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
    CAPTURE_OPERATION_NAME = /run_*(?<operation_name>\w*)/

    class FailStep < StandardError; end
    class HaltStep < StandardError; end
    class HaltOperation < StandardError; end
    class FailOperation < StandardError; end

    def self.included(base)
      base.extend ClassMethods
      base.send :include, InstanceMethods
    end

    module DynamicRun
      def respond_to_missing?(method_name, _include_private = false)
        method_name.match(CAPTURE_OPERATION_NAME)
      end

      def method_missing(method_name, *args, **opts)
        raise NoMethodError, method_name unless respond_to_missing?(method_name)

        CAPTURE_OPERATION_NAME =~ method_name
        run(args.first, operation: operation(operation_name), **opts)
      end
    end

    module ClassMethods
      include DynamicRun

      def operation(name)
        @operations ||= {}
        op = @operations[name] ||= Operation.new(name)
        block_given? ? yield(op) : op
      end

      def track(*args, operation: nil, **options, &block)
        operation(operation || :default).track(*args, **options, &block)
      end

      def tracks
        operation(:default).tracks
      end

      def alias_tracks(mapping = {})
        operation(:default).alias_tracks(mapping)
      end

      def surround_operation(method = nil, &block)
        operation(:default).surrounds << (method || block)
      end

      def run(argument, **opts)
        new.run(argument, operation: operation(:default), **opts)
      end
    end

    module InstanceMethods
      include DynamicRun

      def run(argument, operation:, track_id: 0, step_index: 0)
        run_with_operation_surrounds(
          argument,
          operation: operation,
          operation_surrounds: operation.surrounds,
          track_id: track_id,
          step_index: step_index
        )
      end

      private

      def run_with_operation_surrounds(
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
                       track_index: operation.track_alias(track_id),
                       step_index: step_index
                     )
                   else
                     run_with_operation_surrounds(
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

      def send_surround(surround_definition)
        case surround_definition
        when Symbol
          send(surround_definition) { yield }
        when Array
          surround_definition[0].send(surround_definition[1]) { yield }
        when Proc
          surround_definition.call(-> { yield })
        else
          yield
        end
      end

      def run_steps(argument, track_index:, step_index:, operation:)
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

        begin
          if step_definition
            # If a step definition is found, execute the step definition
            # note that new_argument is passed by reference, and is not
            # returned. Doing this allows us to halt the mid-step.
            run_step(step_definition, new_argument)

            # then pass the modified argument to the next step.
            run_steps(
              new_argument,
              operation: operation,
              track_index: step_definition[:success] || track_index,
              step_index: step_index + 1
            )
          else
            # If there are no step definitions found for a given step
            # of a track, proceed to the next step without any modification
            # to the argument.
            run_steps(
              argument,
              operation: operation,
              track_index: track_index,
              step_index: step_index + 1
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
            step_index: step_index + 1
          )
        rescue HaltOperation
          # This is the version of the argument after it was potentially
          # modified by run_steps. Halting preseverse modifications performed
          # to the argument up to the point it was halted.
          new_argument
        rescue FailStep
          next_track_index = step_definition[:failure] || track_index + 1

          # When a step is failed we rollback any changes performed at that step
          # and continue execution to of the proceeding steps.
          run_steps(
            argument,
            operation: operation,
            track_index: next_track_index,
            step_index: step_index + 1
          )
        rescue FailOperation
          # this the value of the argument prior to it being passed to run_steps
          @original_argument
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

      def operation_surrounds
        self.class.operation_surrounds
      end

      def run_step(step_definition, argument)
        if step_definition[:method].is_a?(Symbol)
          send(step_definition[:method], argument)
        else
          step_definition[:method].call(argument)
        end
      end
    end
  end
end
