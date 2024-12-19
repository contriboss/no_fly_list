# frozen_string_literal: true

require_relative 'lib/no_fly_list/version'

Gem::Specification.new do |spec|
  spec.name = 'no_fly_list'
  spec.version = NoFlyList::VERSION
  spec.authors = [ 'Abdelkader Boudih' ]
  spec.email = [ 'terminale@gmail.com' ]

  spec.summary = 'Tagging system for ActiveRecord models'
  spec.description = 'Tagging system for ActiveRecord models inspired by the TSA'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.files = Dir.glob('{db,lib}/**/*', File::FNM_DOTMATCH)
  spec.require_paths = [ 'lib' ]
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.homepage = 'https://github.com/contriboss/no_fly_list'

  spec.add_dependency 'activerecord', '>= 7.2'
end
