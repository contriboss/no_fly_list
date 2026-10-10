# frozen_string_literal: true

module NoFlyList
  module TaggableRecord
    module Query
      module_function

      # Defines query methods based on database adapter
      # @param setup [TagSetup] Tag setup configuration
      # @return [void]
      # @see PostgresqlStrategy#define_query_methods
      # @see MysqlStrategy#define_query_methods
      # @see SqliteStrategy#define_query_methods
      def define_query_methods(setup)
        case setup.adapter
        when :postgresql
          PostgresqlStrategy.define_query_methods(setup)
        when :mysql
          MysqlStrategy.define_query_methods(setup)
        else
          SqliteStrategy.define_query_methods(setup)
        end
      end

      # Builds a subquery selecting the ids of taggable rows that have at least
      # one tagging in the setup's context, limited to tags named +names+ when
      # given.
      # @param relation [ActiveRecord::Relation] Taggable relation the scope runs on
      # @param setup [TagSetup] Tag setup configuration
      # @param names [Array<String>, nil] Tag names to match
      # @return [Arel::SelectManager] Subquery projecting taggable ids
      def tagged_ids(relation, setup, names = nil)
        taggable_table = relation.arel_table
        tagging_table = setup.tagging_class_name.constantize.arel_table
        tag_table = setup.tag_class_name.constantize.arel_table

        query = Arel::SelectManager.new(relation)
                                   .from(relation.table_name)
                                   .project(taggable_table[relation.primary_key])
                                   .join(tagging_table).on(tagging_table[:taggable_id].eq(taggable_table[relation.primary_key]))
                                   .join(tag_table).on(tag_join_condition(setup, taggable_table, tagging_table, tag_table))
                                   .where(tagging_table[:context].eq(setup.context.to_s.singularize))
        query.where(tagging_table[:taggable_type].eq(relation.name)) if setup.polymorphic
        query.where(name_in(setup, tag_table, names)) if names
        query
      end

      # Join condition from a tagging to its tag. Scoped tags must also share
      # the taggable row's scope value.
      # @return [Arel::Nodes::Node] Join condition
      def tag_join_condition(setup, taggable_table, tagging_table, tag_table)
        condition = tag_table[:id].eq(tagging_table[:tag_id])
        column = setup.scope_column
        column ? condition.and(tag_table[column].eq(taggable_table[column])) : condition
      end

      # SQL counterpart of #tag_join_condition, appended to a raw tag join.
      # @return [String] Extra join condition, empty for unscoped tags
      def scope_join_sql(setup, tag_table_name, taggable_table_name)
        column = setup.scope_column
        column ? " AND #{tag_table_name}.#{column} = #{taggable_table_name}.#{column}" : ""
      end

      # Tag name as compared by the context: the column itself, or LOWER(name)
      # when the context is case insensitive.
      # @return [Arel::Nodes::Node] Name expression
      def name_column(setup, tag_table)
        setup.case_sensitive ? tag_table[:name] : tag_table[:name].lower
      end

      # Condition matching tags named +names+. Case insensitive contexts
      # compare LOWER(name) with LOWER of each value.
      # @return [Arel::Nodes::Node] Name condition
      def name_in(setup, tag_table, names)
        return tag_table[:name].in(names) if setup.case_sensitive

        name_column(setup, tag_table).in(names.map { |name| Arel::Nodes::NamedFunction.new("LOWER", [ Arel::Nodes.build_quoted(name) ]) })
      end

      # +where+ arguments for the raw SQL queries, matching (or with
      # +negate+, excluding) tags named +names+.
      # @return [Array] Arguments for ActiveRecord::QueryMethods#where
      def name_in_sql(setup, tag_table, names, negate: false)
        if setup.case_sensitive
          [ "#{tag_table.name}.name #{negate ? 'NOT IN' : 'IN'} (?)", names ]
        else
          condition = name_in(setup, tag_table, names)
          [ negate ? condition.not : condition ]
        end
      end

      # Requested names without duplicates, ignoring case when the context is
      # case insensitive, so counts compare against distinct names.
      # @return [Array<String>] Distinct names
      def distinct_names(setup, names)
        setup.case_sensitive ? names : names.uniq(&:downcase)
      end

      # SQL counting a row's distinct matching tags: by id, or by LOWER(name)
      # when the context is case insensitive.
      # @return [String] Aggregate expression
      def distinct_tag_count_sql(setup, tag_table)
        setup.case_sensitive ? "COUNT(DISTINCT #{tag_table.name}.id)" : "COUNT(DISTINCT LOWER(#{tag_table.name}.name))"
      end

      module BaseStrategy
        module_function

        # Defines database-specific query methods
        # @abstract
        # @param setup [TagSetup] Tag setup configuration
        def define_query_methods(setup)
          raise NotImplementedError
        end
      end
    end
  end
end
