module RailwayOperation
  module Surround
    def wrap(with:, pass_through: [], &body)
      @body = body
      @pass_through = pass_through
      execute(with)
    end

    private

    def execute(surrounds)
      surround, *rest = surrounds
      argument, info = nil

      send_surround(surround, @pass_through) do
        argument, info = if rest.empty?
                           @body.call(*@pass_through)
                         else
                           execute(rest)
                         end
      end

      [argument, info]
    end

    def send_surround(surround_definition, args)
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
