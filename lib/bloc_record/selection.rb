require 'sqlite3'

module Selection
  def find(id)
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ','} FROM #{table}
      WHERE id = #{id};
    SQL

    data = Hash[columns.zip(row)]
    new(data)
  end
end



def find_by(col, value)
  sql = <<-SQL
    SELECT #{columns.join ","}
    FROM #{table}
    WHERE #{col}=#{value}
  SQL

  rows = connection.execute sql

  data = rows.map { |row| Hash[columns.zip(row)] }
  data.map { |x| new(x) }
end

