# frozen_string_literal: true

require_relative 'lib/no_fly_list/version'

Gem::Specification.new do |spec|
  spec.name = 'no_fly_list'
  spec.version = NoFlyList::VERSION
  spec.authors = [ 'Abdelkader Boudih' ]
  spec.email = [ 'terminale@gmail.com' ]

  spec.summary = 'Modern tagging system for Rails 7.2+ applications'
  spec.description = 'A flexible, high-performance tagging system for Rails applications with support for polymorphic tags, custom transformers, and database-specific optimizations'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.files = Dir.glob('{db,lib}/**/*', File::FNM_DOTMATCH)
  spec.require_paths = [ 'lib' ]
  spec.homepage = 'https://github.com/contriboss/no_fly_list'

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => 'https://github.com/contriboss/no_fly_list',
    'changelog_uri' => 'https://github.com/contriboss/no_fly_list/blob/master/CHANGELOG.md',
    'bug_tracker_uri' => 'https://github.com/contriboss/no_fly_list/issues',
    'rubygems_mfa_required' => 'true',
    'github_repo' => 'ssh://github.com/contriboss/no_fly_list'
  }

  spec.add_dependency 'activerecord', '>= 7.2'
end
