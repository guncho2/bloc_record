require 'bloc_record/persistence'
module BlocRecord
        class Collection < Array
           #5
          def update_all(updates)
            ids = self.map(&:id)
            #6
            self.any? ? self.first.class.update(ids, updates) : false
          end

          def take(num = 1)
            loop_point = 0

            while loop_point < num
              puts self.sample
              loop_point += 1
            end
          end

          def where(params)
            results = BlocRecord::Collection.new
            params_to_meet = params.keys.length
      
            self.each do |item|
              params_met = 0
              params.each do |k, v|
                if item.send(k) == v
                  params_met += 1
                  if params_to_meet == params_met && results.include?(item) == false
                    results << item
                  end
                end
              end
            end
            results
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


        end
 end

 

