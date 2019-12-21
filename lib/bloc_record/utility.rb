module BlocRecord
     module Utility

          extend self

                def underscore(camel_cased_word)
                   string = camel_cased_word.gsub(/::/, '/')
                   string.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')

                   string.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
 
                   string.tr!("-", "_")

                   string.downcase

                end


                def sql_strings(value)
                        case value
                        when String
                                "'#{value}'"
                        when Numeric
                                value.to_s
                        else
                                "null"
                        end
                end

                def convert_keys(options)
                        options.keys.each {|k| options[k.to_s] = options.delete(k) if k.kind_of?(Symbol)}
                        options
                
                end



                def instance_variables_to_hash(obj)
                        Hash[obj.instance_variables.map{ |var| ["#{var.to_s.delete('@')}", obj.instance_variable_get(var.to_s)]}]
                end
                
                # This method is the inverse of Base::initialize. Instead of assigning instance variables from a hash,
                #  it iterates over an object's instance_variables to build a hash representation of them. Ruby prepends
                #   instance variable name strings with @, so we delete that with delete('@') to end up with just
                #    the name of each instance variable.


                def reload_obj(dirty_obj)
                        persisted_obj = dirty_obj.class.find(dirty_obj.id)
                        dirty_obj.instance_variable.each do |instance_variable|
                                dirty_obj.instance_variable_set(instance_variable, persisted_obj.instance_variable_get(instance_variable))

                        
                        end
                end
 



                # This method takes an object, finds its database record using the find method in the Selection 
                # module. It then overwrites the instance variable values with the stored values from the database.
                #          Effectively, this method will discard any unsaved changes to the given object.
        end

end



# At #1, we extend self. In this context, self refers to the Utility class, so 
# underscore will be a class method instead of an instance method. This is helpful 
# so we can run code like BlocRecord::Utility.underscore('TextLikeThis'). This does 
# not require creating an instance of the class before calling it, unlike an instance
#  method. Instance methods are used for manipulating or accessing one particular object.
# Starting at #2, we apply five modifications to the string:
#2 replaces any double colons with a slash using gsub
#3 inserts an underscore between any all-caps class prefixes (like acronyms) and other words
#4 inserts an underscore between any camelcased words
#5 replaces any - with _ using tr
#6 makes the string lowercase
