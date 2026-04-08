# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in no_fly_list.gemspec
gemspec

gem "pg"
rails_version = ENV.fetch("RAILS_VERSION", "~> 8.0")
gem "mysql2"
if rails_version == "edge"
  gem "railties", github: "rails/rails", branch: "main"
  gem "activerecord", github: "rails/rails", branch: "main"
else
  gem "railties", rails_version
end
# shoulda-context has compatibility issues with Rails 8.1+
gem "shoulda-context", "~> 2.0" unless rails_version.match?(/8\.[12]|edge/)
gem "shoulda-matchers"
gem "minitest", "~> 5.0"
gem "sqlite3"
gem "simplecov", require: false
gem "rubocop-rails-omakase"
