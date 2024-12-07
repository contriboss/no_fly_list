# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'shoulda-context'
require 'shoulda-matchers'
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :active_record
  end
end

puts "Rails version: #{Rails.version}"
puts "Ruby version: #{RUBY_VERSION}"
