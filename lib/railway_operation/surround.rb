# frozen_string_literal: true

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
      result = nil

      send_surround(surround, @pass_through) do
        result = if rest.empty?
                   @body.call(*@pass_through)
                 else
                   execute(rest)
                 end
      end

      result
    end

    def send_surround(surround, args)
      case surround
      when Symbol
        send(surround, *args) { yield }
      when Array
        surround[0].send(surround[1], *args) { yield }
      when Proc
        surround.call(-> { yield }, *args)
      else
        yield
      end
    end
  end
end
