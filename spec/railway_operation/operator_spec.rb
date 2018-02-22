# -*- coding: utf-8 -*-
require 'spec_helper'

describe RailwayOperation::Operator do
  context '.track' do
    class Sample1 < described_class
      track 0, :track_0_0
      track 0, :track_0_1, success: 2
      track 1, :track_1_2, failure: 1
      track 0, :track_0_3, success: 4
      track 2, :track_2_4
    end

    class InfiniteSteps < described_class
      def method_missing(method, argument)
        insert_value(argument, method)
      end

      def insert_value(argument, value)
        argument['value'] ||= []
        argument['value'] << value
        argument
      end
    end

    let(:track0) do
      [
        { method: :track_0_0, success: nil, failure: nil },
        { method: :track_0_1, success: 2, failure: nil },
        nil,
        { method: :track_0_3, success: 4, failure: nil }
      ]
    end

    let(:track1) do
      [nil, nil, { method: :track_1_2, success: nil, failure: 1 }]
    end

    let(:track2) do
      [nil, nil, nil, nil, { method: :track_2_4, success: nil, failure: nil }]
    end

    it 'allows tracks to be declare' do
      expect(Sample1.tracks).to eq([track0, track1, track2])
    end
  end

  describe '.run' do
    context 'happy_path' do
      class Sample2 < InfiniteSteps
        track 0, :step1
        track 0, :step2
        track 0, :step3
      end

      it 'executes the steps in the operation' do
        result = Sample2.run
        expect(result['value']).to eq([:step1, :step2, :step3])
      end

      it 'does not mutate arguments passed to the operation' do
        argument = { 'original_value' => "don't change" }
        result = Sample2.run(argument)

        expect(argument).to eq('original_value' => "don't change")
        expect(result).to eq('original_value' => "don't change", 'value' => [:step1, :step2, :step3])
      end
    end

    context 'multiple tracks defined' do
      it 'remains on the same track if step does not fail' do
        class Sample3 < InfiniteSteps
          track 0, :step1
          track 1, :step2
          track 0, :step3
        end

        result = Sample3.run
        expect(result).to eq('value' => [:step1, :step3])
      end

      context 'step failure' do
        class Sample4 < InfiniteSteps
          track 0, :step1
          track 1, :step2
          track 0, :step3
          track 1, :step4
          track 2, :step5

          def step1(_argument)
            raise FailStep.new
          end
        end

        it 'moves to the next track (0 → 1) when a step fails' do
          result = Sample4.run
          expect(result).to eq('value' => [:step2, :step4])
        end
      end
    end
  end
end
