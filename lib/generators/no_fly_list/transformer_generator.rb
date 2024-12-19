# frozen_string_literal: true

require 'forwardable'
require 'rails/generators'
require 'rails/generators/active_record'
require 'rails/generators/named_base'

unless defined?(ApplicationTagTransformer)
  module NoFlyList
    module Generators
      # bin/rails g no_fly_list:transformer
      class TransformerGenerator < Rails::Generators::Base
        source_root File.expand_path('templates', __dir__)
        def create_tag_transformer_file
          template 'tag_transformer.rb', File.join('app/transformers', 'application_tag_transformer.rb')
        end
      end
    end
  end
end
