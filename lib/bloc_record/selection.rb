require 'sqlite3'
require 'bloc_record/persistence'
require 'bloc_record/collection'


module Selection

  def find(*ids)   
    if ids.length == 1
      find_one(ids.first)
    else 
      ids.each do |id|
        if id.is_a?(Integer) && id > 0
          next
        else
          puts "This is not a valid ID"
          return -1
        end
      end
      rows = connection.execute sql sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id IN (#{ids.join(",")});
      SQL

      rows_to_array(rows)
    end
  end

  def find_by(attribute, value)
    row = connection.get_first_row <<-SQL
     SELECT #{columns.join ","} FROM #{table}
     WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
    SQL
    init_object_from_row(row)
  end
  


  def take(num=1)
    if num > 1
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY random()
        LIMIT #{num};
      SQL
      rows_to_array(rows)
      else
        take_one
    end
  end


  def take_one

    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL
    init_object_from_row(row)
  end

  def first
    row = connection.get_first_row <<-SQL
     SELECT #{columns.join","} FROM #{table}
     ORDER BY id
     ASC LIMIT 1;
    SQL
    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row <<-SQL
     SELECT #{columns.join","} FROM #{table}
     ORDER BY id
     DESC LIMIT 1;
    SQL
    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL
    rows_to_array(rows)
  end


def find_each(options={})
  start = options[:start]
  batch_size = options[:batch_size]
  if start != nil && batch_size != nil
    rows = connection.execute <<-SQL
     SELECT #{columns.join ","} FROM #{table}
     LIMIT #{batch_size} OFFSET #{start};
    SQL
  elsif start == nil && batch_size != nil
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      LIMIT #{batch_size};
    SQL
  elsif start != nil && batch_size == nil
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      OFFSET #{start};
    SQL
  else
    rows = connection.execute <<-SQL
      SELCT #{columns.join ","} FROM #{table};
    SQL
  end

  rows.each do |row|
    yield init_object_from_row(row)
  end
end


def find_in_batches(options={})
  start = options[:start]
  batch_size = options[:batch_size]
  if start != nil && batch_size != nil
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      LIMIT #{batch_size} OFFSET #{start};
    SQL
  elsif start == nil && batch_size != nil
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      LIMIT #{batch_size};
    SQL
  elsif start != nil && batch_size == nil
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      OFFSET #{start};
    SQL
  else
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL
  end

  row_array = rows_to_array(rows)
  yield(row_array)
end


def find_one(id)
  if id.is_a?(Integer) && id > 0
   row = connection.get_first_row <<-SQL
    SELECT #{columns.join ","} FROM #{table}
    WHERE id = #{id};
   SQL
   init_object_from_row(row)
  else
    puts "This is not a valid ID"
    return -1
  end
 end

 def not(params)
  results = BlocRecord::Collection.new
  self.each do |item|
    params.each do |k, v|
      if item.send(k) != v && results.include?(item) == false
        results << item
      end
    end
  end
  results
end

def where(*args)
  if args.count > 1
    expression = args.shift
    params = args
  else
      case args.first
      when String
        expression = args.first
            #Entry.where("phone_number = '999-999-9999
      when Symbol
        expression = args.first.to_s        
      when Hash
        expression_hash = BlocRecord::Utility.convert_keys(args.first)
        expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}" }.join(" and ")
      
        #Entry.where(name: 'BlocHead')
      end
  end
  sql = <<-SQL
    SELECT #{columns.join ","} FROM #{table}
    WHERE #{expression};
  SQL
  rows = connection.execute(sql, params)
  rows_to_array(rows)
end

# In this example, we're handling array input by checking whether args.count > 1.
# This SQL statement is very familiar to us. The only change is, predictably, the WHERE clause, which scopes the
#  response to args.shift. shift "removes the first element of self and returns it (shifting all other elements down by one)."
# The remaining arguments are passed in to connection.execute, which handles the question mark replacement for us.


# def order(order)
#   order = order.to_s

#  Entry.order("name", "phone_number") Entry.order(:name, :phone_number) To accomplish this, we'll use the splat
 #operator, and join the elements if the resulting Array has multiple elements:

def order(*args)
  orderArray = []
    args.each do |arg|
      case arg
        when String
         orderArray << arg
        when Symbol
         orderArray << arg.to_s
        when Hash
         orderArray << arg.map{|key, value| "#{key} #{value}"}
      end
    end
  order = orderArray.join(",")
  puts order
  rows = connection.execute <<-SQL
    SELECT * FROM #{table}
    ORDER BY #{order};
  SQL
  rows_to_array(rows)
end

  #If the order local variable is a Symbol, to_s will convert it to a string. If it's already a String,
  #to_s will have no effect and the string will be interpolated directly into the SQL query.

  
  # def join(arg)
  #   if arg.class == String  
    
  #     rows = connection.execute <<-SQL
  #       SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(arg)};
  #     SQL
  #   elsif arg.class == Symbol
  #     rows = connection.execute <<-SQL
  #       SELECT * FROM #{table}
  #       INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id
  #     SQL

  #   end

  #   rows_to_array(rows)
  # end

  

  def join(*args)

    if args.count > 1
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      rows = connection.execute <<-SQL
        SELECT * FROM #{table} #{joins}
      SQL
    else
      case args.first
        when String
          rows = connection.execute <<-SQL
            SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
          SQL
        when Symbol
          rows = connection.execute <<-SQL
            SELECT * FROM #{table}
            INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
          SQL

        when Hash
         key = args.first.keys.first
         value = args.first[key]
          puts "#{key}, #{value}"
          rows = connection.execute <<-SQL
           SELECT * FROM #{table}
           INNER JOIN #{key} ON #{key}.#{table}_id = #{table}.id
  	       INNER JOIN #{value} ON #{value}.#{key}_id = #{key}.id
  	      SQL
       end
     end
    rows_to_array(rows)
   end

#   If arg is a Symbol, we'll create a very specific SQL statement. For example, 
# calling Employee.join(:department) would result in this query:
# SELECT * FROM employee
# INNER JOIN department ON department.employee_id = employee.id

# def method_missing(method_name, *args)
#   if method_name.match(/find_by/)
#     attribute = method_name.to_s.split('find_by_')[1]
#     if columns.include?(attribute)
#       find_by(attribute, *args)
#     else
#       puts "#{attribute} is not at the DB"
#     end
#   else
#     puts "#{methid_name} is not available"
#     end
# end

def method_missing(method_name, *args)
  if method_name.match(/find_by/)
    attribute = method_name.to_s.split('find_by_')[1]
    if columns.include?(attribute)
      self.find_by(attribute, args.first)
    else
      puts "#{attribute} does not exist in the database -- please try again."
    end
  elsif method_name.match(/update_/)
    attribute = method_name.to_s.split('update_')[1]
    if self.class.columns.include?(attribute)
      self.class.update(self.id,{attribute => args.last})
    else
      puts "#{attribute} does not exist in the database -- please try again."
    end
  else
    super
  end
end




private

  def init_object_from_row(row)
    if row 
      data = Hash[columns.zip(row)]
      new(data)
    end
  end
  
  def rows_to_array(rows)
    rows.map { |row| new(Hash[columns.zip(row)])}
  end

  # def rows_to_array(rows)
  #   collection = BlocRecord::Collection.new
  #   rows.each { |row| collection << new(Hash[columns.zip(row)]) }
  #   collection
  # end




  
end



