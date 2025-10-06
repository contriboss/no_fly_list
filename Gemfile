# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in no_fly_list.gemspec
gemspec

gem "pg"
rails_version = ENV.fetch("RAILS_VERSION", "~> 8.0")
gem "mysql2"
gem "railties", rails_version
# shoulda-context has compatibility issues with Rails 8.1+
gem "shoulda-context", "~> 2.0" unless rails_version.match?(/8\.1/)
gem "shoulda-matchers"
gem "sqlite3"
gem "simplecov", require: false
gem "rubocop-rails-omakase"
