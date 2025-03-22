# frozen_string_literal: true

require "simplecov"
SimpleCov.start

ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"
require "rails/test_help"
require "shoulda-context"
require "shoulda-matchers"
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :active_record
  end
end

# test/test_helper.rb or similar
module ActiveSupport
  class TestCase
    # Normalize SQL for test comparisons
    def normalize_sql(sql)
      sql.gsub(/\s+/, " ")          # Collapse multiple spaces into one
         .gsub("( ", "(")           # Remove space after opening parenthesis
         .gsub(" )", ")")           # Remove space before closing parenthesis
         .strip                     # Trim leading and trailing whitespace
    end

    # Return symbol for the model adapter
    def model_adapter(model)
      model.connection.adapter_name.downcase.to_sym
    end
  end
end
puts "Using #{ENV['DB_ADAPTER']} adapter" if ENV["DB_ADAPTER"]
puts "Rails version: #{Rails.version}"
puts "Ruby version: #{RUBY_VERSION}"
