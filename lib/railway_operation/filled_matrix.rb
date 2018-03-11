# frozen_string_literal: true

module RailwayOperation
  class FilledMatrix
    include Enumerable

    def initialize(*rows, row_type: Array)
      @row_type = row_type
      @matrix = EnsuredAccess.new(@row_type.new(rows)) do
        EnsuredAccess.new(@row_type.new)
      end

      ensure_rows_length_are_equal!
    end

    def [](row_index, column_index = nil)
      if column_index
        @matrix.__getobj__[row_index] &&
          @matrix.__getobj__[row_index][column_index]
      else
        @matrix.__getobj__[row_index] || EnsuredAccess.new(@row_type.new)
      end
    end

    def []=(row_index, column_index, entry)
      @max_column_index = nil # bust the max_column_index cache

      @matrix[row_index][column_index] = entry
      ensure_rows_length_are_equal!

      @matrix
    end

    def each
      @matrix.each do |row|
        yield row
      end
    end

    def max_column_index
      @max_column_index ||= (@matrix.compact.max_by(&:length) || []).length - 1
    end

    private

    def ensure_rows_length_are_equal!
      @matrix.each_with_index do |_column, index|
        @matrix[index][max_column_index] ||= nil
      end
    end
  end
end
