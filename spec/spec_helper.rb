# frozen_string_literal: true

require 'pry-byebug'
require 'bundler/setup'
require 'helpers/infinite_steps'
require 'helpers/fake_logger'
require 'helpers/complex_example'

require 'railway_operation'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
