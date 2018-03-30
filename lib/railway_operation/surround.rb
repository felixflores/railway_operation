# frozen_string_literal: true

module RailwayOperation
  module Surround
    def wrap(*surrounds, arguments: [], &body)
      @body = body
      @arguments = arguments

      execute(surrounds)
    end

    private

    def execute(surrounds)
      surround, *rest = surrounds
      result = nil

      send_surround(surround, *@arguments) do
        result = if rest.empty?
                   @body.call
                 else
                   execute(rest)
                 end
      end

      result
    end

    def send_surround(surround, *args)
      case surround
      when Symbol # wrap(with: :my_method)
        send(surround, *args) { yield }
      when Array # wrap(with: [MyClass, :method])
        surround[0].send(surround[1], *args) { yield }
      when Proc # wrap(with: -> { ... })
        surround.call(-> { yield }, *args)
      else # no wrap
        yield(*args)
      end
    end
  end
end
