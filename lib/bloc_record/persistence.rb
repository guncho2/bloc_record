require 'sqlite3'
require 'bloc_record/schema'
require 'bloc_record/selection'
# require 'bloc_record/error_handling'


module Persistence

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
      
        def update_attribute(attribute, value)
          self.class.update(self.id, { attribute => value})
        end

        def update_attributes(updates)
          self.class.update(self.id, updates)
        end


        #update_attribute passes self.class.update its own id and a hash of the attributes that should be updated.
         #self.class is used to gain access to an unknown object's class. We need this to call update since it is a 
         #class method rather than an instance method (defined in the module ClassMethods).
         #The instance method has two parameters: attribute and value. attribute is used as the name of the attribute
          #to which value is assigned.


      module ClassMethods

          def update_all(updates)
            update(nil, updates)
          end
          
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

                

                def update_mult(ids, updates)
                  if updates.is_a? Array
                    count = 0
                    while count < ids.length
                      update(ids[count], updates[count])
                      count += 1
                    end
                  else
                    update(ids, updates)
                  end
                end


                def update(ids, updates)
                  
                  updates = BlocRecord::Utility.convert_keys(updates)
                  updates.delete "id"
                  
                  updates_array = updates.map { |key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}" }
                  
                  # where_clause = id.nil? ? ";" : "WHERE id = #{id};"
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

                  true
                end

                def method_missing(method_name, *args)
                  if method_name.match(/find_by/)
                    attribute = method_name.to_s.split('find_by_')[1]
                    if columns.include?(attribute)
                      self.find_by(attribute, args.first)
                    else
                      puts "#{attribute} does not exist in the database -- please try again."
                    end
                  elsif method_name.match(/update_mult/)
                    attribute = method_name.to_s.split('update_mult_')[1]
                    if self.class.columns.include?(attribute)
                      self.class.update_mult(self.id, { attribute => args.last } )
                    else
                      puts "#{attribute} does not exist in the database -- please try again."
                    end
                  else
                    super
                  end
                end
                
        
        end
end