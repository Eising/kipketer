class Array
    def sum
        inject(0.0) { |result, el| result + el }
    end

    def mean
        sum / size
    end
end
class Hastighedstest < Sinatra::Base
    # Extract thrulay results from JSON document
    #
    # @param result [JSON] The JSON formatted results column from the database
    # @return A result hash including `:average`, `:max` and `:min` values
    def get_thrulay_results(result)
        # This function expects the JSON formatted results column from the db
        data = JSON.parse(result)
        numbers = []
        data["output"]["data"].each { |v| numbers << v[1] }
        { :average => numbers.mean.round(2), :max => numbers.max.round(2), :min => numbers.min.round(2) }
    end

    # Validate thrulay results
    #
    # @param result_id [Integer] The database id of the result set
    # @param min_percentage The percentage of CIR that the test must hit to
    #   validate
    # @return true or false
    def validate_thrulay_results(result_id, min_percentage)
        result = Results.where(:id => result_id)
        raise Sinatra::NotFound if result.count == 0
        raise Sinatra::NotFound if result.first.results.nil?
        raise "Invalid percentage" unless min_percentage.class == Fixnum
        average = get_thrulay_results(result.first.results)[:average]
        cir = result.first.test.speed.to_f
        res = average / cir * 100
        if (min_percentage..100).include? res
            return true
        elsif res > 100
            return true
        else
            return false
        end
    end
end
