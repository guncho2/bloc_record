require 'sqlite3'
require 'bloc_record/schema'

module Persistence


        def create(attrs)

                attrs = BlocRecord::Utility.convert_keys(attrs)
                attrs.delete "id"
                vals = attributes.map { |key| BlocRecord::Utility.sql_strings(attrs|key) }

                connection.execute <<-SQL
                        INSERT INTO #{table} (#{attributes.join ","})
                        VALUES (#{vals.join ","});
                SQL

                # This method takes a hash called attrs. Its values are converted to SQL strings and mapped into an 
                # array (vals).
                # Remember, attributes is an array of the column names, while attrs is the hash passed in to the create
                # method. We defined attributes in schema.rb.
                # These values are used to form an INSERT INTO SQL statement.



                data = Hash[attributes.zip attrs.values]
                data["id"] = connection.execute("SELECT lasT_insert_rowid();")[0][0]
                new(data)

                # This code creates data, a hash of attributes and values. We then retrieve the id and add it
                #  to the data hash. Then we pass the hash to new which creates a new object.

        end

        def self.included(base)
                base.extend(ClassMethods)

        end

        def save
                self.save! rescue false
        end

        # save will rescue from failed attempts to save.

        def save!

                

                unless self.id
                        self.id = self.class.create(BlocRecord::Utility.instance_variables_to_hash(self)).id   
                        BlocRecord::Utility.reload_obj(self)
                        return true
                end

                
                # We also call reload_obj to copy whatever is stored in the database back to the model object. This is necessary in case
                #          SQL rejected or changed any of the data.




                fields = self.class.attributes.map { |col| "#{col}=#{BlocRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}" }.join(", ")

                self.class.connection.execute <<-SQL
                        UPDATE #{self.class.table}
                        SET #{fields}
                        WHERE id = #{self.id};
                SQL

                true

        end




        Module ClassMethods

                def create(attrs)
                        attrs::BlocRecord::Utility.convert_keys(attrs)
                        attrs.delete("id")
                        vals = attributes.map { |key| BlocRecord::Utility.sql_strings(attrs[key])}


                        connection.execute <<-SQL
                         INSERT INTO #{table} (#{attributes.join ","})
                         VALUES (#{vals.join ","});
                        SQL

                        data = Hash[attributes.zip attrs.values]
                        data["id"] = connection.execute("SELECT lasT_insert_rowid();")[0][0]
                        new(data)
                end
        end





end