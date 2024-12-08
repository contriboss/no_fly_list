# frozen_string_literal: true

module NoFlyList
  module TaggableRecord
    module Query
      module_function

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

        def case_insensitive_where(table, column, values)
          raise NotImplementedError
        end

        def define_query_methods(setup)
          raise NotImplementedError
        end
      end
    end
  end
end
