require 'sqlite3'
require 'active_support/inflector'

# association = entries self = AddressBook

module Associations
        def has_many(association)
#1
                define_method(association) do 
#2
                        rows = self.class.connection.execute <<-SQL
                                SELECT * FROM #{association.to_s.singularize}
                                WHERE #{self.class.table}_id = #{self.id}
                        SQL
                       #3  
                        class_name = association.to_s.classify.constantize
                        collection = BlocRecord::Collection.new
#4
                        rows.each do |row|
                                collection << class_name.new(Hash[class_name.column.zip(row)])
                        end
#5
                        collection

                end

        end

        def has_one(association)
                define_method(association) do
                        rows = self.class.connection.execute <<-SQL
                                SELECT * FROM #{association.to_s.singularize}
                                WHERE #{self.class.table}_id = #{self.id}
                        SQL

                        class_name = association.to_s.classify.constantize
                        row = rows.first
                        return class_name.new(Hash[class_name.column.zip(row)])
                        LIMIT 1


                end
        end

        def belongs_to(association)
                define_method(association) do
                        association_name = association.to_s
                        row = self.class.connection.get_first_row <<-SQL
                                SELECT * FROM #{association_name}
                                WHERE id = #{self.send(association_name + "_id")}
                        SQL

                        class_name = association.to_s.classify.constantize

                        if row
                                data = Hash[class_name.column.zip(row)]
                                class_name.new(data)
                        end
                end
        end


end

#remember that association will always be a plural noun. 
#As we explain the code, we'll say that association is equal to :entries and that self 
#is an instance of AddressBook.
#1, define_method adds an instance method called entries to the AddressBook class.
#Calling define_method adds a new method to a class at runtime. This command is useful 
#for adding methods to objects while your program is running, which is necessary if
 #you don't know what those methods should be named while you're writing your code. 
 #This Stack Overflow post shows some examples of adding a speak method to a Cow class.
 #At #2, we execute a SQL query similar to this:
 #SELECT * FROM entry
#WHERE address_book_id = 123
#The singularize inflector method changed entries to entry.
#3, we create a new class name. classify creates the appropriate string name ('Entry'), 
#and constantize converts the string to the actual class (the Entry class).
#4, we iterate each SQL record returned, and serialize it into an Entry object, which 
#is added to collection
#5, we return collection.



