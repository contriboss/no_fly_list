# frozen_string_literal: true

module PersonTagTransformer
  module_function

  # @param tags [String|Array<String>]
  def parse_tags(tags)
    if tags.is_a?(Array)
      tags
    else
      tags.split(separator).map(&:strip)
    end
  end

  # Recreate a string from an array of tags
  # @param tags [Array<String>]
  # @return [String]
  def recreate_string(tags)
    tags.join(separator)
  end

  # @return [String]
  def separator
    '/'
  end
end
