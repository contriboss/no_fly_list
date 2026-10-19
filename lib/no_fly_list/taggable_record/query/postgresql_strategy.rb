# frozen_string_literal: true

module NoFlyList
  module TaggableRecord
    module Query
      module PostgresqlStrategy
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
                                         .join(tag_table).on(Query.tag_join_condition(setup, arel_table, tagging_table, tag_table))
                                         .where(tagging_table[:context].eq(singular_name))
                                         .where(Query.name_in(setup, tag_table, tags))

              where(arel_table[primary_key].in(query))
            }

            scope "with_all_#{context}", lambda { |*tags|
              tags = tags.flatten.compact.uniq
              return none if tags.empty?

              count_function = Arel::Nodes::NamedFunction.new(
                "COUNT",
                [ Arel::Nodes::NamedFunction.new("DISTINCT", [ Query.name_column(setup, tag_table) ]) ]
              )

              query = Arel::SelectManager.new(self)
                                         .from(table_name)
                                         .project(arel_table[primary_key])
                                         .join(tagging_table).on(tagging_table[:taggable_id].eq(arel_table[primary_key]))
                                         .join(tag_table).on(Query.tag_join_condition(setup, arel_table, tagging_table, tag_table))
                                         .where(tagging_table[:context].eq(singular_name))
                                         .where(Query.name_in(setup, tag_table, tags))
                                         .group(arel_table[primary_key])
                                         .having(count_function.eq(Query.distinct_names(setup, tags).size))

              where(arel_table[primary_key].in(query))
            }

            # Find records without any of the specified tags
            scope "without_any_#{context}", lambda { |*tags|
              tags = tags.flatten.compact.uniq
              return all if tags.empty?

              where(arel_table[primary_key].not_in(Query.tagged_ids(self, setup, tags)))
            }

            # Find records without any tags
            scope "without_#{context}", lambda {
              return where(arel_table[primary_key].not_in(Query.tagged_ids(self, setup))) if setup.scope_column

              subquery = if setup.polymorphic
                           setup.tagging_class_name.constantize
                                .where(context: singular_name)
                                .where(taggable_type: name)
                                .select(:taggable_id)
              else
                           setup.tagging_class_name.constantize
                                .where(context: singular_name)
                                .select(:taggable_id)
              end

              where.not(primary_key => subquery)
            }

            # Find records with exactly these tags
            scope "with_exact_#{context}", lambda { |*tags|
              tags = tags.flatten.compact.uniq

              if tags.empty?
                send("without_#{context}")
              else
                Arel::Nodes::NamedFunction.new(
                  "COUNT",
                  [ Arel::Nodes::NamedFunction.new("DISTINCT", [ tag_table[:id] ]) ]
                )

                # Build the query for records having exactly the tags
                all_tags_query = select(arel_table[primary_key])
                                 .joins("INNER JOIN #{tagging_table.name} ON #{tagging_table.name}.taggable_id = #{table_name}.#{primary_key}")
                                 .joins("INNER JOIN #{tag_table.name} ON #{tag_table.name}.id = #{tagging_table.name}.tag_id#{Query.scope_join_sql(setup, tag_table.name, table_name)}")
                                 .where("#{tagging_table.name}.context = ?", context.to_s.singularize)
                                 .where(*Query.name_in_sql(setup, tag_table, tags))
                                 .group(arel_table[primary_key])
                                 .having("#{Query.distinct_tag_count_sql(setup, tag_table)} = ?", Query.distinct_names(setup, tags).size)

                # Build query for records with other tags
                other_tags_query = select(arel_table[primary_key])
                                   .joins("INNER JOIN #{tagging_table.name} ON #{tagging_table.name}.taggable_id = #{table_name}.#{primary_key}")
                                   .joins("INNER JOIN #{tag_table.name} ON #{tag_table.name}.id = #{tagging_table.name}.tag_id#{Query.scope_join_sql(setup, tag_table.name, table_name)}")
                                   .where("#{tagging_table.name}.context = ?", context.to_s.singularize)
                                   .where(*Query.name_in_sql(setup, tag_table, tags, negate: true))

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
