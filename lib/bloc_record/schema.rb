require 'sqlite3'
require 'bloc_record/utility'

module Schema
    def table
        BlocRecord::Utility.underscore(name)
    end

        #     When we include Schema in a class, this will allow us to call table on an object to 
        #     retrieve its SQL table name. For example, if we have a BookAuthor class, BookAuthor.table
        #      would return book_author.

    def schema
        unless @schema
                @schema = {}
                connection.table_info(table) do |col|
                        @schema[col['name']] = col["type"]

                end
        end
        @schema
    end

   #     The result of calling schema might look like:
   # {"id"=>"integer", "name"=>"text", "age"=>"integer"}

   def columns
        schema.keys
   end

   # columns would return ["id", "name", "age"].

   def attributes
        columns - ["id"]
   end

        #    We'll also write a method to return the column names except id:


        # method called count, that returns a count of records 
        # in a table. Here's where we'll start to build the connection between Ruby and SQL

   def count 
        connection.execute(<<-SQL)[0][0]
           SELECT COUNT(*) FROM #{table}
        SQL
   end


                #    We could've have also written:
                # connection.execute("SELECT COUNT(*) FROM #{table}")[0][0]
                # execute is a SQLite3::Database instance method. It takes a SQL statement, executes it,
                #  and returns an array of rows (records), each of which contains an array of columns. [0][0] 
                #  extracts the first column of the first row, which will contain the count.



end

