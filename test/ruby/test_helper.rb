# frozen_string_literal: true

if ENV["COVERAGE"] == "true"
  require "simplecov"
end

require "minitest/autorun"

Minitest.after_run do
  puts <<~EOS

   [TIP] To rerun tests with the exact same seed, execute:
         SEED=#{Minitest.seed} rake test
  EOS
end
