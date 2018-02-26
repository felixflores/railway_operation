# frozen_string_literal: true

module FakeLogger
  def log(index)
    @log ||= []
    @log[index] ||= []
    @log[index]
  end

  def clear_log
    @log = []
  end
end
