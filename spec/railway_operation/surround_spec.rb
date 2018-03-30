# frozen_string_literal: true

require 'spec_helper'

module RailwayOperation
  class TestSurround
    extend Surround

    def self.reset_log
      @log = []
    end

    def self.log(message = nil)
      @log ||= []
      @log << message if message
      @log
    end

    def self.test
      setup
      log
    end

    def self.surround1(argument = nil)
      log("surround1_before_#{argument}")
      yield
      log("surround1_after_#{argument}")
    end

    def self.surround2(argument = nil)
      log("surround2_before_#{argument}")
      yield
      log("surround2_after_#{argument}")
    end

    def self.body(argument = nil)
      log("body_during_#{argument}")
    end
  end
end

describe RailwayOperation::TestSurround do
  describe '#wrap' do
    after { described_class.reset_log }

    it 'wraps body with surround' do
      def described_class.setup
        wrap(:surround1) { body }
      end

      expect(described_class.test).to eq(
        [
          'surround1_before_',
          'body_during_',
          'surround1_after_'
        ]
      )
    end

    it 'is allowed to be called without any surround' do
      def described_class.setup
        wrap(nil) { body }
      end

      expect(described_class.test).to eq(['body_during_'])
    end

    it 'can nest surrounds' do
      def described_class.setup
        wrap(:surround1, :surround2) { body }
      end

      expect(described_class.test).to eq(
        [
          'surround1_before_',
          'surround2_before_',
          'body_during_',
          'surround2_after_',
          'surround1_after_'
        ]
      )
    end

    it 'can pass argument to surround but not the body' do
      def described_class.setup
        wrap(:surround1, arguments: 'passing') { body }
      end

      expect(described_class.test).to eq(
        [
          'surround1_before_passing',
          'body_during_',
          'surround1_after_passing'
        ]
      )
    end

    context 'types of surrounds' do
      after { described_class.reset_log }

      it 'can be a symbols which calls an instance method' do
        def described_class.setup
          wrap(:surround1) { body }
        end

        expect(described_class.setup).to eq(
          [
            'surround1_before_',
            'body_during_',
            'surround1_after_'
          ]
        )
      end

      it 'can be an array containing a class and class method' do
        def described_class.setup
          wrap([self, :surround1]) { body }
        end

        expect(described_class.test).to eq(
          [
            'surround1_before_',
            'body_during_',
            'surround1_after_'
          ]
        )
      end

      it 'can by a proc' do
        def described_class.setup
          wrap(
            lambda do |step|
              log('proc_before')
              step.call
              log('proc_after')
            end
          ) { body }
        end

        expect(described_class.test).to eq(
          [
            'proc_before',
            'body_during_',
            'proc_after'
          ]
        )
      end
    end
  end
end
