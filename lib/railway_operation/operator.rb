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
    CAPTURE_OPERATION_NAME = /run_*(?<operation>\w*)/

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

      def method_missing(method_name, argument, **opts)
        raise NoMethodError, method_name unless respond_to_missing?(method_name)
        operation = method_name.match(CAPTURE_OPERATION_NAME)[:operation]

        run(
          argument,
          operation: operation,
          **opts
        )
      end
    end

    module SendSurround
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

    module ClassMethods
      include DynamicRun
      include SendSurround

      def operation(op)
        @operations ||= {}
        the_op = if op.is_a?(Operation)
                   op
                 else
                   @operations[op.to_sym] ||= Operation.new(name.to_sym)
                 end

        block_given? ? yield(the_op) : the_op
      end

      def add_step(*args, operation: nil, **options, &block)
        if operation.is_a?(Operation)
          operation.add_step(*args, **options, &block)
        else
          operation(operation || :default).add_step(*args, **options, &block)
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

    module InstanceMethods
      include DynamicRun
      include SendSurround

      def run(argument, operation: :default, track_id: 0, step_index: 0)
        operation = self.class.operation(operation)
        set_operation_defaults!(operation)

        run_with_operation_surrounds(
          argument,
          operation: operation,
          operation_surrounds: operation.surrounds,
          track_id: track_id,
          step_index: step_index
        )
      end

      private

      def set_operation_defaults!(operation)
        default_operation = self.class.operation(:default)

        [:surrounds, :step_surrounds, :track_alias].each do |attr|
          if operation.send(attr).empty?
            operation.send("#{attr}=", default_operation.send(attr))
          end
        end

        if operation.fails_step.empty?
          operation.fails_step(*default_operation.fails_step)
        end
      end

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
                       track_index: operation.track_index(track_id),
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

      def run_steps(argument, track_index:, step_index:, operation:, **options)
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
              **options
            )

            # then pass the modified argument to the next step.
            run_steps(
              new_argument,
              operation: operation,
              track_index: step_definition[:success] || track_index,
              step_index: step_index + 1,
              **options
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
              **options
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
            **options
          )
        rescue HaltOperation
          # This is the version of the argument after it was potentially
          # modified by run_steps. Halting preseverse modifications performed
          # to the argument up to the point it was halted.
          new_argument
        rescue FailOperation
          # this the value of the argument prior to it being passed to run_steps
          @original_argument
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
            **options
          )
        end
      end

      def run_step_with_surround(
        surrounds:,
        step_definition:,
        argument:,
        step_index:,
        **options
      )
        first, *rest = surrounds

        result = nil
        send_surround(first, argument, step_index) do
          result = if rest.empty?
                     run_step(step_definition, argument, **options)
                   else
                     run_step_with_surround(rest, step_definition, argument, **options)
                   end
        end

        result
      end

      def run_step(step_definition, argument, **options)
        if step_definition[:method].is_a?(Symbol)
          send(step_definition[:method], argument, **options)
        else
          step_definition[:method].call(argument, **options)
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
    end
  end
end
