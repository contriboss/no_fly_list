# frozen_string_literal: true

module NoFlyList
  module TaggableRecord
    module Query
      module_function

      def define_query_methods(setup)
        context = setup.context
        taggable_klass = setup.taggable_klass
        singular_name = context.to_s.singularize

        taggable_klass.class_eval do
          # Find records with any of the specified tags
          scope "with_any_#{context}", lambda { |*tags|
            tags = tags.flatten.compact.uniq
            return none if tags.empty?

            joins(:"#{singular_name}_taggings")
              .joins(context)
              .where("#{singular_name}_taggings": { context: singular_name })
              .where(context => { name: tags })
              .distinct
          }

          # Find records without any tags
          scope "without_#{context}", lambda {
            where.not(
              id: setup.tagging_class_name.constantize.where(context: singular_name).select(:taggable_id)
            )
          }

          # Find records with all specified tags
          scope "with_all_#{context}", lambda { |*tags|
            tags = tags.flatten.compact.uniq
            return none if tags.empty?

            tag_count = tags.size
            joins(:"#{singular_name}_taggings")
              .joins(context)
              .where("#{singular_name}_taggings": { context: singular_name })
              .where(context => { name: tags })
              .group(:id)
              .having("COUNT(DISTINCT #{context}.name) = ?", tag_count)
          }

          # Find records without specific tags
          scope "without_any_#{context}", lambda { |*tags|
            tags = tags.flatten.compact.uniq
            return all if tags.empty?

            where.not(
              id: joins(:"#{singular_name}_taggings")
                    .joins(context)
                    .where("#{singular_name}_taggings": { context: singular_name })
                    .where(context => { name: tags })
                    .select(:id)
            )
          }

          # Find records with exactly these tags
          scope "with_exact_#{context}", lambda { |*tags|
            tags = tags.flatten.compact.uniq

            if tags.empty?
              send("without_#{context}")
            else
              # Get records with the exact count of specified tags
              having_exact_tags =
                joins(:"#{singular_name}_taggings")
                .joins(context)
                .where("#{singular_name}_taggings": { context: singular_name })
                .where(context => { name: tags })
                .group(:id)
                .having("COUNT(DISTINCT #{context}.name) = ?", tags.size)
                .select(:id)

              # Exclude records that have any other tags
              having_exact_tags.where.not(
                id: joins(:"#{singular_name}_taggings")
                      .joins(context)
                      .where("#{singular_name}_taggings": { context: singular_name })
                      .where.not(context => { name: tags })
                      .select(:id)
              )
            end
          }

          # Count tags for each record
          scope "#{context}_count", lambda {
            left_joins(:"#{singular_name}_taggings")
              .where("#{singular_name}_taggings": { context: singular_name })
              .group(:id)
              .select("#{table_name}.*, COUNT(DISTINCT #{singular_name}_taggings.id) as #{context}_count")
          }
        end
      end
    end
  end
end
