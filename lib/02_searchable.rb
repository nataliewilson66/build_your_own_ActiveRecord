require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    # ...
    where_line = params.keys.map { |key| "#{key} = ?" }.join(" AND ")
    vals = params.values
    results = DBConnection.execute(<<-SQL, *vals)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL
    return [] unless results.length > 0

    results.map { |params| self.new(params) }
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
