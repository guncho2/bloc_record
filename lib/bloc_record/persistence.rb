require 'sqlite3'
require 'bloc_record/schema'
require 'bloc_record/selection'
require 'bloc_record/collection'
module Persistence
  def update_attribute(attribute, value)
    self.class.update(self.id, { attribute => value})
  end

  
  def update_attributes(updates)
    self.class.update(self.id, updates)
  end

  #We may have an instance of a model object that we want to delete like so: e = Entry.first e.destroySince each model
   #Since each model object knows its own id, we can delegate the work to the class method:

   def destroy
    self.class.destroy(self.id)
   end

  

        def self.included(base)
          base.extend(ClassMethods)
        end

        def save
          self.save!rescue false
        end



                 
        def save!
         unless self.id
           self.id = self.class.create(BlocRecord::Utility.instance_variables_to_hash(self)).id
           BlocRecord::Utility.reload_obj(self)
           return true
         end
                  
           fields = self.class.attributes.map { |col| "#{col}=#{BlocRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}" }.join(",")
        
           self.class.connection.execute <<-SQL
             UPDATE #{self.class.table}
             SET #{fields}
             WHERE id = #{self.id};
           SQL
        
           true
        end
      
        module ClassMethods

          #We might want to destroy all records: Entry.destroy_all For example, we might want to do this before 
          #seeding or importing a new set of records.

          # def destroy_all
          #   connection.execute <<-SQL
          #    DELETE FROM #{table}
          #   SQL
          #    true
          # end

          #Destroy All Records With Conditions, Let's say we want to remove all users who are exactly 20 years old: User.destroy_all(age: 20)
          #To accomplish this, let's modify destroy_all to accept an optional conditions_hash:

          def destroy_all(condition_params=nil)
            if condition_params && !condition_params.empty?

              case condition_params
                
              when Hash

                condition_params = BlocRecord::Utility.convert_keys(condition_params)
                conditions = condition_params.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")

              when String

                conditions = condition_params

              when Array

                conditions = condition_params.join("\nOR ")

              end
             
      
              connection.execute <<-SQL
                DELETE FROM #{table}
                WHERE #{conditions};
              SQL
            else
              connection.execute <<-SQL
                DELETE FROM #{table}
              SQL
            end
            true
          end

          #Now any conditions that are passed in will be appended in a WHERE statement like: DELETE FROM user WHERE age=20;


          def update_all(updates)
            update(nil, updates)
          end
#Let's modify this method to support deleting more than one item. As usual, we'll use the splat operator to force
 #the argument into an Array and check its length:

#  Entry.destroy(1, 2, 3) instead of Entry.destroy(1)

          #def destroy(id)
           def destroy(*id)
            if id.length > 1
              where_clause = "WHERE id IN (#{id.join(",")});"
            else
              where_clause = "WHERE id = #{id.first};"
            end
                 
            connection.execute <<-SQL
             DELETE FROM #{table} #{where_clause}
            SQL
            true

          end

          #Which would result in this SQL query:
          #DELETE FROM entry
          #WHERE id IN (1,2,3);




                def create(attrs)
                  attrs = BlocRecord::Utility.convert_keys(attrs)
                  attrs.delete "id"
                  vals = attributes.map { |key| BlocRecord::Utility.sql_strings(attrs[key]) }
                
                  connection.execute <<-SQL
                        INSERT INTO #{table} (#{attributes.join ","})
                        VALUES (#{vals.join ","});
                  SQL
                
                  data = Hash[attributes.zip attrs.values]
                  data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
                  new(data)
                end


                # def update_mult(ids, updates)
                #   if updates.is_a? Array
                #     count = 0
                #     while count < ids.length
                #       update(ids[count], updates[count])
                #       count += 1
                #     end
                #   else
                #     update(ids, updates)
                #   end
                # end


                def update(ids, updates)
                  case updates
                  when Hash
                    updates_array = build_updates_array(updates)
            
                    if ids.class == Fixnum
                      where_clause = "WHERE id = #{ids};"
                    elsif ids.class == Array
                      where_clause = ids.empty? ? ";" : "WHERE id IN (#{ids.join(",")});"
                    else
                      where_clause = ";"
                    end
            
                    connection.execute <<-SQL
                      UPDATE #{table}
                      SET #{updates_array * ","} #{where_clause}
                    SQL
                  when Array
                    if ids.class == Fixnum
                    if ids.size != updates.size
            
                    updates.each do |update, index|
                      updates_array = build_updates_array(update)
            
                      connection.execute <<-SQL
                        UPDATE #{table}
                        SET #{updates_array * ","} WHERE id = #{ids[index]};
                      SQL
                    end
                  end
            
                  true
                end

                private

                def build_updates_array(hash)
                  hash = BlocRecord::Utility.convert_keys(hash)
                  hash.delete "id"
                  hash_array = hash.map { |key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}" }
                end
              end 

        end
      end
end