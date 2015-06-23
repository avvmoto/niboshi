module Yaffle
  module ActsAsYaffle
    extend ActiveSupport::Concern

    GROONGA_ESCAPE_CHARS = %q{() \'"} # http://groonga.org/ja/docs/reference/grn_expr/query_syntax.html

    included do
      scope :mroonga_match, ->(query, columns) do
        # TODO: more validation, more security

        # Args
        # query:  String
        # colums: String, separated by ','

        raise ArgumentError if query.blank? || columns.blank?

        query = self.connection.quote(query)

        where("MATCH(#{columns}) AGAINST(mroonga_escape(#{query}, '#{GROONGA_ESCAPE_CHARS}') IN BOOLEAN MODE)")
      end

      scope :mroonga_snippet, ->(query, column, options = {}) do
        raise(ArgumentError, "specify both query and column") if query.blank? || column.blank?

        # escape
        options.each { |key, value|
          options[key] = self.connection.quote(value) unless value.blank?
        }

        # args of mroonga_snippet()
        keyword_prefix = options[:keyword_prefix] || "<span>"
        keyword_suffix = options[:keyword_suffix] || "</span>"
        max_bytes = options[:max_bytes] || 1500
        max_count = options[:max_count] || 1
        encoding = options[:encoding] || "utf8mb4_unicode_ci"
        skip_leading_spaces = options[:skip_leading_spaces] || 1
        html_escape = options[:html_escape] || 1
        snippet_prefix = options[:snippet_prefix] || ""
        snippet_suffix = options[:snippet_suffix] || ""
        result_column_prefix = options[:result_column_prefix] || "hilighted_"

        query = "mroonga_escape(#{self.connection.quote(query)}, '#{GROONGA_ESCAPE_CHARS}')"
        snippet_query = "#{query}, '#{keyword_prefix}', '#{keyword_suffix}'"
        snippet = "mroonga_snippet(#{column}, #{max_bytes}, #{max_count}, '#{encoding}', #{skip_leading_spaces}, #{html_escape}, '#{snippet_prefix}', '#{snippet_suffix}', #{snippet_query} ) AS #{result_column_prefix}#{column}"

        select_with_new_column(snippet)
      end

      scope :select_with_new_column, ->(query) {
        result = current_scope || relation
        result = result.select('*') if result.select_values.blank?
        result.select(query)
      }

    end

    module ClassMethods
      def acts_as_yaffle(options = {})
        cattr_accessor :yaffle_text_field
        self.yaffle_text_field = (options[:yaffle_text_field] || :last_squawk).to_s

        include Yaffle::ActsAsYaffle::LocalInstanceMethods
      end
    end

    module LocalInstanceMethods
      def squawk(string)
        write_attribute(self.class.yaffle_text_field, string.to_squawk)
      end
    end
  end
end
 
ActiveRecord::Base.send :include, Yaffle::ActsAsYaffle
