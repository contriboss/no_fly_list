# frozen_string_literal: true

module NoFlyList
  module TaggableRecord
    module Query
      module SqliteStrategy
        extend BaseStrategy

        module_function

        def define_query_methods(setup)
          context = setup.context
          taggable_klass = setup.taggable_klass
          tagging_klass = setup.tagging_class_name.constantize
          tagging_table = tagging_klass.arel_table
          tag_klass = setup.tag_class_name.constantize
          tag_table = tag_klass.arel_table
          singular_name = context.to_s.singularize

          taggable_klass.class_eval do
            # Find records with any of the specified tags
            scope "with_any_#{context}", lambda { |*tags|
              tags = tags.flatten.compact.uniq
              return none if tags.empty?

              query = Arel::SelectManager.new(self)
                                         .from(table_name)
                                         .project(arel_table[primary_key])
                                         .distinct
                                         .join(tagging_table).on(tagging_table[:taggable_id].eq(arel_table[primary_key]))
                                         .join(tag_table).on(tag_table[:id].eq(tagging_table[:tag_id]))
                                         .where(tagging_table[:context].eq(singular_name))
                                         .where(tag_table[:name].in(tags))

              where(arel_table[primary_key].in(query))
            }

            scope "with_all_#{context}", lambda { |*tags|
              tags = tags.flatten.compact.uniq
              return none if tags.empty?

              count_function = Arel::Nodes::NamedFunction.new(
                'COUNT',
                [Arel::Nodes::NamedFunction.new('DISTINCT', [tag_table[:name]])]
              )

              query = Arel::SelectManager.new(self)
                                         .from(table_name)
                                         .project(arel_table[primary_key])
                                         .join(tagging_table).on(tagging_table[:taggable_id].eq(arel_table[primary_key]))
                                         .join(tag_table).on(tag_table[:id].eq(tagging_table[:tag_id]))
                                         .where(tagging_table[:context].eq(singular_name))
                                         .where(tag_table[:name].in(tags))
                                         .group(arel_table[primary_key])
                                         .having(count_function.eq(tags.size))

              where(arel_table[primary_key].in(query))
            }

            # Find records without any of the specified tags
            scope "without_any_#{context}", lambda { |*tags|
              tags = tags.flatten.compact.uniq
              return all if tags.empty?

              # Build dynamic joins
              tagged_ids = distinct
                           .joins("INNER JOIN #{tagging_table} ON #{tagging_table}.taggable_id = #{table_name}.id")
                           .joins("INNER JOIN #{context} ON #{context}.id = #{tagging_table}.tag_id")
                           .where("#{context}.name IN (?)", tags)
                           .pluck("#{table_name}.id")

              # Handle empty tagged_ids explicitly for SQLite compatibility
              where("#{table_name}.id NOT IN (?)", tagged_ids.present? ? tagged_ids : [-1])
            }

            # Find records without any tags
            scope "without_#{context}", lambda {
              subquery = if setup.polymorphic
                           setup.tagging_class_name.constantize
                                .where(context: singular_name, taggable_type: name)
                                .select(:taggable_id)
                         else
                           setup.tagging_class_name.constantize
                                .where(context: singular_name)
                                .select(:taggable_id)
                         end
              where('id NOT IN (?)', subquery)
            }

            # Find records with exactly these tags
            scope "with_exact_#{context}", lambda { |*tags|
              tags = tags.flatten.compact.uniq

              if tags.empty?
                send("without_#{context}")
              else
                Arel::Nodes::NamedFunction.new(
                  'COUNT',
                  [Arel::Nodes::NamedFunction.new('DISTINCT', [tag_table[:id]])]
                )

                # Build the query for records having exactly the tags
                all_tags_query = select(arel_table[primary_key])
                                 .joins("INNER JOIN #{tagging_table.name} ON #{tagging_table.name}.taggable_id = #{table_name}.#{primary_key}")
                                 .joins("INNER JOIN #{tag_table.name} ON #{tag_table.name}.id = #{tagging_table.name}.tag_id")
                                 .where("#{tagging_table.name}.context = ?", singular_name)
                                 .where("#{tag_table.name}.name IN (?)", tags)
                                 .group(arel_table[primary_key])
                                 .having("COUNT(DISTINCT #{tag_table.name}.id) = ?", tags.size)

                # Build query for records with other tags
                other_tags_query = select(arel_table[primary_key])
                                   .joins("INNER JOIN #{tagging_table.name} ON #{tagging_table.name}.taggable_id = #{table_name}.#{primary_key}")
                                   .joins("INNER JOIN #{tag_table.name} ON #{tag_table.name}.id = #{tagging_table.name}.tag_id")
                                   .where("#{tagging_table.name}.context = ?", singular_name)
                                   .where("#{tag_table.name}.name NOT IN (?)", tags)

                # Combine queries using subqueries
                where("#{table_name}.#{primary_key} IN (?)", all_tags_query)
                  .where("#{table_name}.#{primary_key} NOT IN (?)", other_tags_query)
              end
            }

            # Add tag counts
            # Find records with exactly these tags
            scope "with_exact_#{context}", lambda { |*tags|
              tags = tags.flatten.compact.uniq

              if tags.empty?
                send("without_#{context}")
              else
                Arel::Nodes::NamedFunction.new(
                  'COUNT',
                  [Arel::Nodes::NamedFunction.new('DISTINCT', [tag_table[:id]])]
                )

                # Build the query for records having exactly the tags
                all_tags_query = select(arel_table[primary_key])
                                 .joins("INNER JOIN #{tagging_table.name} ON #{tagging_table.name}.taggable_id = #{table_name}.#{primary_key}")
                                 .joins("INNER JOIN #{tag_table.name} ON #{tag_table.name}.id = #{tagging_table.name}.tag_id")
                                 .where("#{tagging_table.name}.context = ?", context.to_s.singularize)
                                 .where("#{tag_table.name}.name IN (?)", tags)
                                 .group(arel_table[primary_key])
                                 .having("COUNT(DISTINCT #{tag_table.name}.id) = ?", tags.size)

                # Build query for records with other tags
                other_tags_query = select(arel_table[primary_key])
                                   .joins("INNER JOIN #{tagging_table.name} ON #{tagging_table.name}.taggable_id = #{table_name}.#{primary_key}")
                                   .joins("INNER JOIN #{tag_table.name} ON #{tag_table.name}.id = #{tagging_table.name}.tag_id")
                                   .where("#{tagging_table.name}.context = ?", context.to_s.singularize)
                                   .where("#{tag_table.name}.name NOT IN (?)", tags)

                # Combine queries
                where("#{table_name}.#{primary_key} IN (?)", all_tags_query)
                  .where("#{table_name}.#{primary_key} NOT IN (?)", other_tags_query)
              end
            }
          end
        end
      end
    end
  end
end
