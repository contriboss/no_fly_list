# No Fly List

[![Gem Version](https://badge.fury.io/rb/no_fly_list.svg)](https://badge.fury.io/rb/no_fly_list)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)

A modern, modular tagging system built specifically for Rails 7.2+ applications. 
Focused on simplicity and modern Rails patterns.

## Requirements

- Rails 7.2 or higher
- Ruby 3.2 or higher
- PostgreSQL, MySQL, or SQLite3

## Features

- **Modern Rails First**: Built specifically for Rails 7.2+, leveraging the latest Active Record features
- **Flexible Tag Contexts**: Define multiple tag categories per model
- **Polymorphic or Model-Specific Tags**: Choose between shared tags across models or model-specific tags
- **Tag Restrictions**: Optional limiting of allowed tags and maximum tag count
- **Custom Class Names**: Override tag and tagging class names per model
- **Database Agnostic**: Native support for PostgreSQL, MySQL and SQLite with optimized queries
- **Multiple Tag Input Formats**: Support for arrays, strings, and comma-separated values
- **Counter Cache**: Optional counter cache for tag counts
- **Custom Tag Separators**: Configurable tag separators via transformers
- **Case Sensitivity Options**: Control case sensitivity of tag matching
- **Tag Validation**: Built-in validation for tag limits and existing tags
- **Autosave Support**: Automatic saving of tag changes with parent record
- **Query Optimization**: Database-specific query strategies for better performance

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

This creates `app/transformers/application_tag_transformer.rb`:

```ruby
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

### Database Setup

For global tags:
```bash
$ rails generate no_fly_list:install
$ rails db:migrate
```

For model-specific tags:
```bash
$ rails generate no_fly_list:tagging Article
$ rails db:migrate
```

## Usage

### Basic Setup

```ruby
class Article < ApplicationRecord
  include NoFlyList::TaggableRecord
  
  # Basic usage
  has_tags :topics

  # With all options
  has_tags :categories,
    polymorphic: true,               # Use global tags table
    restrict_to_existing: true,      # Only allow existing tags
    limit: 5,                        # Maximum tags per record
    counter_cache: true,             # Enable counter cache
    case_sensitive: false,           # Case insensitive tags
    transformer: CustomTransformer,  # Custom tag parsing
    tag_class_name: "CustomTag",     # Custom tag class
    tagging_class_name: "CustomTagging"  # Custom tagging class
end
```

### Tag Operations

```ruby
# Adding tags
article.topics_list.add("rails, api")      # Comma-separated string
article.topics_list.add(["rails", "api"])  # Array
article.topics_list.add("rails", "api")    # Multiple arguments

# Removing tags
article.topics_list.remove("rails, api")   # Comma-separated string
article.topics_list.remove(["rails"])      # Array
article.topics_list.remove("rails", "api") # Multiple arguments

# Setting tags
article.topics_list = "rails, api"
article.topics_list = ["rails", "api"]

# Clearing tags
article.topics_list.clear    # Marks for deletion
article.topics_list.clear!   # Immediately deletes

# Saving changes
article.topics_list.save     # Returns false on failure
article.topics_list.save!    # Raises on failure
```

### Querying

```ruby
# With any tags
Article.with_any_topics(["rails", "api"])
Article.with_any_topics("rails, api")

# With all tags
Article.with_all_topics(["rails", "api"])

# With exact tags
Article.with_exact_topics(["rails", "api"])

# Without specific tags
Article.without_any_topics(["rails"])

# Without any tags
Article.without_topics

# Combining queries
Article.with_any_topics("rails")
      .with_all_categories("tutorial")
```

### Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `polymorphic` | `false` | Use shared tags table across models |
| `restrict_to_existing` | `false` | Only allow existing tags |
| `limit` | `nil` | Maximum tags per record |
| `counter_cache` | `false` | Enable counter cache column |
| `case_sensitive` | `true` | Case sensitive tag matching |
| `transformer` | `ApplicationTagTransformer` | Custom tag parsing |
| `tag_class_name` | `ModelTag` | Custom tag class name |
| `tagging_class_name` | `Model::Tagging` | Custom tagging class name |

### Custom Transformers

```ruby
module CustomTransformer
  module_function

  def parse_tags(tags)
    if tags.is_a?(Array)
      tags
    else
      tags.split(separator).map(&:strip).map(&:downcase).compact
    end
  end

  def separator
    ' | '  # Custom separator
  end
  
  def recreate_string(tags)
    tags.join(separator)
  end
end

class Article < ApplicationRecord
  has_tags :topics, transformer: CustomTransformer
end

article.topics_list = "Rails | API"  # Stored as ["rails", "api"]
```

## Testing Support

The gem includes test helpers:

```ruby
class ArticleTest < ActiveSupport::TestCase
  include NoFlyList::TestHelper
  
  test "tagging setup" do
    assert_taggable_record Article, :topics, :categories
    assert_tagging_context Article, :topics, polymorphic: true
    assert_has_tag @article, "rails", :topics
    assert_has_no_tag @article, "python", :topics
  end
end
```

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
