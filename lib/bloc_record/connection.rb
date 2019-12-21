require 'sqlite3'

module Connection
    def connection
        @connection ||= SQLite3::Database.new(BlocRecord.database_filename)
    end
end

# A new Database object will be initialized from the file the first time connection is called.
