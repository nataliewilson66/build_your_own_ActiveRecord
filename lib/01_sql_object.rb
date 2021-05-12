require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    table_data = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      LIMIT
        0
    SQL
    @columns = table_data.first.map { |el| el.to_sym }
  end

  def self.finalize!
    cols = self.columns
    cols.each do |col|
      define_method(col) { attributes[col] }
      define_method("#{col}=") { |val| attributes[col] = val }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.name.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
    SQL
    self.parse_all(results)
  end

  def self.parse_all(results)
    results.map { |params| self.new(params) }
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = ?
    SQL
    return nil unless result.length > 0

    self.new(result.first)
  end

  def initialize(params = {})
    attr_names = params.keys
    cols = self.class.columns
    params.each do |attr_name, val|
      attr_name = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless cols.include?(attr_name)
      self.send("#{attr_name}=", val)
    end
  end

  def attributes
    @attributes || @attributes = {}
  end

  def attribute_values
    cols = self.class.columns
    vals = cols.map { |col| self.send(col) }
  end

  def insert
    cols = self.class.columns
    col_names = cols.join(", ")
    question_marks = (["?"] * cols.length).join(", ")
    DBConnection.execute(<<-SQL, *self.attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    
    self.id = DBConnection.last_insert_row_id
  end

  def update
    cols = self.class.columns[1..-1]
    set_line = cols.map { |attr_name| "#{attr_name} = ?"}.join(", ")
    DBConnection.execute(<<-SQL, *self.attribute_values[1..-1], self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
