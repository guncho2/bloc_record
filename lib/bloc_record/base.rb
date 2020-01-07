require 'bloc_record/utility'
require 'bloc_record/schema'
require 'bloc_record/selection'
require 'bloc_record/persistence'
require 'bloc_record/connection'

# Base will have a minimal implementation. Most of its functionality will be composed from other 
# modules. We could add the module methods directly to Base, but placing them in separate modules 
# makes the code more readable and easier to understand.

module BlocRecord
        class Base

                # extend Persistence
                include Persistence
                extend Selection
                extend Schema
                extend Connection

                def initialize(options={})
                        options = BlocRecord::Utility.convert_keys(options)
                        
                        self.class.columns.each do |col|
                                self.class.send(:attr_accessor, col)
                                self.instance_variable_set("@#{col}", options[col])
                        end
                        
                
                end
        end
end

 # After filtering the options hash using convert_keys, this method iterates over each column.
 #  This method uses self.class to get the class's dynamic, runtime type, and calls columns on
 #   that type. If BookAuthor inherits from Base, self.class would be equivalent to BookAuthor.class.
 # In the each block, we do two things:
 # Use Object::send to send the column name to attr_accessor. This creates an instance variable getter and setter 
 # for each column.
 # Use Object::instance_variable_set to set the instance variable to the value corresponding to that key in the options hash.
 # For example, if options was:
 # {"character_name"=>"Jar-Jar Binks"}
 # This code would create a new instance variable named character_name and assign Jar-Jar Binks as its value.




 