# No Fly List

[![Gem Version](https://badge.fury.io/rb/no_fly_list.svg)](https://badge.fury.io/rb/no_fly_list)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)

A modern, modular tagging system built specifically for Rails 7.2+ applications. Focused on simplicity and modern Rails patterns.

## Requirements

- Rails 7.2 or higher
- Ruby 3.2 or higher

## Features

- **Modern Rails First**: Built specifically for Rails 7.2+, leveraging the latest Active Record features
- **Flexible Tag Contexts**: Define multiple tag categories per model
- **Polymorphic or model owned Tags**: Choose between shared tags across models or model-specific tags
- **Tag Restrictions**: Optional limiting of allowed tags and maximum tag count
- **Custom Class Names**: Override tag and tagging class names per model

[Previous sections remain the same until Installation]

## Installation

Add to your Gemfile:

```ruby
gem 'no_fly_list'
```

Then run:

```bash
$ bundle install
```

### Required: Tag Transformer Setup

The transformer defines how tags are parsed and presented. Run:

```bash
$ rails generate no_fly_list:transformer
```

This will create `app/transformers/application_tag_transformer.rb`, which handles tag parsing and formatting. Here's the default implementation:

```ruby
# frozen_string_literal: true

module ApplicationTagTransformer
  module_function

  def parse_tags(tags)
    if tags.is_a?(Array)
      tags
    else
      tags.split(separator).map(&:strip).compact
    end
  end

  def recreate_string(tags)
    tags.join(separator)
  end

  def separator
    ','
  end
end
```

You can customize the transformer by modifying any of these methods:
- `parse_tags`: Controls how tags are parsed from input
- `recreate_string`: Controls how tags are converted back to strings
- `separator`: Defines the character(s) used to separate tags (default: comma)

Example of a custom separator:

```ruby
module PipedTagTransformer
  module_function

  def separator
    ' | '  # Use pipe character as separator
  end
  
  # Other methods remain the same...
end
```

### Global Tags Setup (Optional)

Run this if you want to use global tags shared across models:

```bash
$ rails generate no_fly_list:install
$ rails db:migrate
```

### Model-Specific Tags

Generate tagging for a specific model:

```bash
$ rails generate no_fly_list:tagging Article
$ rails db:migrate
```

## Usage

### Basic Setup

```ruby
class Article < ApplicationRecord
  include NoFlyList::Taggable
  
  # Basic usage with default options
  has_tags :topics, :categories
  
  # With options
  has_tags :skills, 
    polymorphic: true,                    # Use global tags table
    restrict_to_existing: true,      # Only allow existing tags
    limit: 5,                        # Maximum 5 tags per record
    tag_class_name: "CustomTag",     # Custom tag class
    tagging_class_name: "CustomTagging"  # Custom tagging class
end
```

### Options

| Option | Default | Description                                                |
|--------|---------|------------------------------------------------------------|
| `polymorphic` | `false` | When true, uses a shared tags table across multiple models |
| `restrict_to_existing` | `false` | When true, only allows using tags that already exist       |
| `limit` | `nil` | Sets maximum number of tags allowed per record             |
| `tag_class_name` | `"Tag"` | Overrides the tag class name for this model                |
| `tagging_class_name` | `"Tagging"` | Overrides the tagging class name for this model            |

### Tagging Operations

```ruby
# Add tags
article = Article.new(title: "Modern Rails")
article.topic_list.add("rails", "web")
article.save

# Remove tags
article.topic_list.remove("web")

# Replace all tags
article.topic_list = ["rails", "api"]

# Access tags
article.topic_list  # => ["rails", "api"]
```

### Querying

```ruby
# Find records with any of the specified topic tags
Article.with_any_topics(["rails", "api"])

# Find records with all specified topic tags
Article.with_all_topics(["rails", "api"])

# Find records without any topic tags
Article.without_topics

# Find records without specific topic tags
Article.without_any_topics(["rails", "api"])

# Find records with exactly these topic tags (no more, no less)
Article.with_exact_topics(["rails", "api"])

# Get records with tag counts
Article.topics_count
```

Query methods are automatically created for each tag context. Replace `topics` in the examples above with your tag context name.

Options available for each query type:

- `with_any_[context]`: Finds records that have any of the specified tags
- `with_all_[context]`: Finds records that have all of the specified tags
- `without_[context]`: Finds records that have no tags in this context
- `without_any_[context]`: Finds records that don't have any of the specified tags
- `with_exact_[context]`: Finds records that have exactly these tags (no more, no less)
- `[context]_count`: Returns records with their tag counts

## Versioning and Compatibility

- This gem follows Semantic Versioning (2.0.0)
- Only the latest versions of Rails (7.2+) is officially supported
- Backporting of features to older Rails versions will not occur
- Critical bug fixes may be backported on a case-by-case basis

## Roadmap

Future features under consideration:
- Caching support
- Tag popularity tracking
- Tag hierarchies
- Advanced tag suggestions
- I18n integration

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Add tests for your changes
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin feature/my-new-feature`)
6. Create new Pull Request

Please note that we only support Rails 7.2+ for new features. Bug fixes may be considered for earlier versions depending on severity.

## License

Released under the [MIT License](LICENSE.txt).

## Credits

Inspired by acts-as-taggable-on, but rebuilt specifically for modern Rails applications.