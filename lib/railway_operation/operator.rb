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

    module ClassMethods
      def track_alias(mapping = {})
        @track_alias = (@track_alias || {}).merge(mapping)
        @track_alias
      end

      def surround_operation(method = nil, &block)
        operation_surrounds << (method || block)
      end

      def operation_surrounds
        @operation_surrounds ||= []
      end

      def track(track_index, method = nil, failure: nil, success: nil, &block)
        @step_count ||= 0

        fetch_track(track_index)[@step_count] = {
          method: method || block,
          success: success,
          failure: failure
        }

        @step_count += 1
        tracks
      end

      def tracks
        @tracks ||= []
      end

      def run(argument)
        # Find the first track with a step defined
        track_index = tracks.index { |v| !v.nil? }
        step_index = 0

        new.run(argument, track_index, step_index)
      end

      def fetch_track(index)
        index = index.is_a?(Numeric) ? index : track_alias[index]
        tracks[index] ||= []
        tracks[index]
      end
    end

    module InstanceMethods
      def run(argument, track_index = 0, step_index = 0)
        run_with_operation_surrounds(
          operation_surrounds: self.class.operation_surrounds,
          argument: argument,
          track_index: track_index,
          step_index: step_index
        )
      end

      private

      def run_with_operation_surrounds(
        operation_surrounds:,
        argument:,
        track_index:,
        step_index:
      )
        first, *rest = operation_surrounds

        result = nil
        send_surround(first) do
          result = if rest.empty?
                     run_steps(argument, track_index, step_index)
                   else
                     run_with_operation_surrounds(
                       operation_surrounds: rest,
                       argument: argument,
                       track_index: track_index,
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
          send(:null_surround) { yield }
        end
      end

      def null_surround
        yield
      end

      def run_steps(argument, track_index = 0, step_index = 0)
        return argument if step_index > last_step_index

        # We memoize the version of the argument which was passed
        # to run_steps at the first iteration of the recursion
        # this allows us to return it in case the the operation fails
        @original_argument ||= argument # see rescue FailOperation

        # We are doing the clone early so that the new_argument
        # could be mutated in context of the operation step,
        # SwitchTrack or HaltExecution and maintain the mutations
        # to the argument thus far
        new_argument = argument.clone
        step_definition = self.class.fetch_track(track_index)[step_index]

        begin
          if step_definition
            # If a step definition is found, execute the step definition
            # note that new_argument is passed by reference, and is not
            # returned. Doing this allows us to halt the mid-step.
            run_step(step_definition, new_argument)

            # then pass the modified argument to the next step.
            run_steps(
              new_argument,
              step_definition[:success] || track_index,
              step_index + 1
            )
          else
            # If there are no step definitions found for a given step
            # of a track, proceed to the next step without any modification
            # to the argument.
            run_steps(argument, track_index, step_index + 1)
          end
        rescue HaltStep
          next_track_index = step_definition[:success] || track_index

          # When we halt a step, we preserve the changes to the argument so far
          # in that step, and proceed to the next step with the modified
          # argument.
          run_steps(new_argument, next_track_index, step_index + 1)
        rescue HaltOperation
          # This is the version of the argument after it was potentially
          # modified by run_steps. Halting preseverse modifications performed
          # to the argument up to the point it was halted.
          new_argument
        rescue FailStep
          next_track_index = step_definition[:failure] || track_index + 1

          # When a step is failed we rollback any changes performed at that step
          # and continue execution to of the proceeding steps.
          run_steps(argument, next_track_index, step_index + 1)
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

      def last_step_index
        @last_step_index ||= (tracks.compact.max_by(&:length) || []).length - 1
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
