# frozen_string_literal: true

module RailwayOperation
  class FilledMatrix
    include Enumerable

    def initialize(*rows)
      @matrix = rows
      ensure_rows_length_are_equal!
    end

    def [](row_index, column_index)
      return unless @matrix[row_index]
      @matrix[row_index][column_index]
    end

    def []=(row_index, column_index, entry)
      @matrix[row_index] ||= []
      @matrix[row_index][column_index] = entry
      ensure_rows_length_are_equal!

      entry
    end

    def to_a
      @matrix
    end

    def each
      @matrix.each do |row|
        yield row
      end
    end

    def max_column_index
      (@matrix.compact.max_by(&:length) || []).length - 1
    end

    private

    def ensure_rows_length_are_equal!
      @matrix.each_with_index do |_column, index|
        @matrix[index] ||= []
        @matrix[index][max_column_index] ||= nil
      end
    end
  end
end
