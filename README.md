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
- **Scoped Tags**: Keep a separate set of tags per tenant, account or workspace
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

If you add `has_tags` before generating this file, the library will attempt to
constantize `'ApplicationTagTransformer'`. If it's missing, a warning is output
and `NoFlyList::DefaultTransformer` will be used instead. Create
`ApplicationTagTransformer` (or specify another transformer) to avoid the
warning.

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

### Scoped tags (multi-tenancy)

Tag names are unique across the whole tag table by default, so every record
tagged "VIP" shares one tag. Pass `scope:` to give each tenant its own tags:

```ruby
class Lead < ApplicationRecord
  include NoFlyList::TaggableRecord

  belongs_to :entity
  has_tags :tags, scope: :entity
end
```

Generate the tag tables with the scope column:

```bash
$ rails generate no_fly_list:tagging Lead --scope=entity
```

The tag table gets an `entity_id` column, and names are unique per entity:

```ruby
create_table :lead_tags, id: :bigint do |t|
  t.column :entity_id, :bigint, null: false
  t.string :name, null: false
  # timestamps...
end

add_index :lead_tags, %i[entity_id name], unique: true
```

How scoped tags behave:

- `scope:` names a `belongs_to` association. Its foreign key is the scope
  column, and the tag table needs a column with the same name. A column name
  (`scope: :entity_id`) works too. Polymorphic `belongs_to` associations are
  not supported.
- Tags are found and created by name within the record's scope. Two entities
  using "VIP" get separate tags, and renaming one leaves the other alone.
- `restrict_to_existing` only accepts tags that exist in the record's scope.
- The query scopes (`with_any_tags`, `with_all_tags`, `with_exact_tags`,
  `without_any_tags`, `without_tags`) only count tags in each record's own
  scope. Add your own condition to search one tenant:
  `Lead.where(entity: entity).with_any_tags("VIP")`.
- Contexts that share a tag class must use the same scope. Declaring them with
  different scopes raises `ArgumentError`.
- A tag keeps the scope it was created in. When a record moves to another
  scope, its old tags stop matching queries until its tag list is saved again.
- List a scope's tags through the tag model: `LeadTag.where(entity_id: entity.id)`.

Global tags take the same option. Generate the global table with
`rails generate no_fly_list:install --scope=entity` and declare
`has_tags :labels, polymorphic: true, scope: :entity`. The scope column covers
the whole global table, so give every polymorphic context the same scope: an
unscoped context looks tags up by name alone and can pick up a tag from any
scope.

### Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `polymorphic` | `false` | Use shared tags table across models |
| `restrict_to_existing` | `false` | Only allow existing tags |
| `limit` | `nil` | Maximum tags per record |
| `counter_cache` | `false` | Enable counter cache column |
| `case_sensitive` | `true` | Match names case sensitively when finding tags, checking `restrict_to_existing` and in the query scopes |
| `scope` | `nil` | `belongs_to` association (or column) that keeps tags unique per scope |
| `transformer` | `'ApplicationTagTransformer'` | Custom tag parsing |
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

### Single Table Inheritance (STI)

For STI models, subclasses must explicitly specify the parent's tag and tagging classes:

```ruby
class Vehicle < ApplicationRecord
  include NoFlyList::TaggableRecord

  has_tags :features
end

class Bicycle < Vehicle
  has_tags :terrain_types, tag_class_name: "VehicleTag", tagging_class_name: "Vehicle::Tagging"
end

class Motorcycle < Vehicle
  has_tags :engine_types, tag_class_name: "VehicleTag", tagging_class_name: "Vehicle::Tagging"
end
```

All subclasses share the same `vehicle_tags` and `vehicle_taggings` tables.

Due to the metaprogramming nature of `has_tags` and the wide range of Rails versions supported (7.2 through 8.2+), automatic STI detection is intentionally avoided. Explicit `tag_class_name` and `tagging_class_name` options on subclasses keep the configuration predictable across Rails upgrades — your STI setup will work the same way on Rails 7.2 as it does on 8.2, with no hidden behavior changes. Without these options, the library would generate non-existent classes like `BicycleTag` and `Bicycle::Tagging`.

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
