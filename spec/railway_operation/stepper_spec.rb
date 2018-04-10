# frozen_string_literal: true

require 'spec_helper'

describe RailwayOperation::Stepper do
  context 'execution manipulator' do
    describe '#continue' do
      it 'returns the vector' do
        expect(subject.continue).to eq(subject.vector)
      end
    end

    describe '#switch_to' do
      let(:operation) { instance_double(RailwayOperation::Operation) }

      context 'specified_track is a symbol' do
        let(:track) { :specified_track }
        let(:info) do
          { operation: operation, execution: [] }
        end

        it 'returns the specified track' do
          track_vector = subject.switch_to(track)
          expect(operation).to receive(:track_index).with(track)
          expect(track_vector.call(info)).to eq(track)
        end
      end

      context 'specified_track is a lambda' do
        let(:info) do
          {
            operation: operation,
            execution: [
              instance_double(RailwayOperation::Step, track_identifier: :specified_track)
            ]
          }
        end

        let(:track) do
          lambda do |_operation, current_track|
            "#{current_track} test"
          end
        end

        it 'returns the track resulting from lambda' do
          track_vector = subject.switch_to(track)
          expect(operation).to receive(:track_index).with('specified_track test')
          expect(track_vector.call(info)).to eq('specified_track test')
        end
      end
    end
  end
end
