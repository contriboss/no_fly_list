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

      module BaseStrategy
        module_function

        # Performs case-insensitive column comparison
        # @param table [Arel::Table] Database table
        # @param column [Symbol] Column name
        # @param values [Array<String>] Values to compare
        # @return [Arel::Node] Query node
        # @abstract
        def case_insensitive_where(table, column, values)
          raise NotImplementedError
        end

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
