require 'sqlite3'
require 'pg'

module Connection
    def connection
        if BlocRecord.database_type == :sqlite3

        @connection ||= SQLite3::Database.new(BlocRecord.database_filename)
        
        elsif BlocRecord.database_type == :pg

            @connection = PG.connect(dbname: BlocRecord.database_filename)

        end
    end

end


# A new Database object will be initialized from the file the first time connection is called.
