class Hastighedstest < Sinatra::Base

    # @!group REST API

    # @method api_tests
    # Returns all tests, default formatted in JSON
    get '/api/tests' do
        data = Tests.select(:id, :crid, :customer, :location, :timestamp, :deadline, :rfs, :deleted).all
        format_response(data, request.accept)
    end

    # @method api_test_id
    # returns a given test in JSON
    get '/api/test/:id' do
        test = Tests.where(:id => params[:id])
        if test.count == 0
            halt(404)
        else
            data = test.first.to_hash
            data[:template_fields] = JSON.parse(data[:template_fields]) 
            format_response(data, request.accept)
        end
    end

    # @method api_test_crid
    # filters tests by CRID
    get '/api/test/crid/:crid' do
        # Method to get test by CRID
        args = { :crid => params[:crid] }
        if params.has_key? "rfs"
            if params[:rfs] =~ /^(1|true)$/
                args[:rfs] = true
            elsif params[:rfs] =~ /^(0|false)$/
                args[:rfs] = nil
            end
        end
        if params.has_key? "deleted"
            if params[:deleted] =~ /^(1|true)$/
                args[:deleted] = true
            elsif params[:deleted] =~ /^(0|false)$/
                args[:deleted] = nil
            end

        end

        test = Tests.where(args)
        if test.count == 0
            halt(404)
        else
            response = []
            data = test.all
            data.each do |resp|
                tresp = resp.to_hash
                tresp[:template_fields] = JSON.parse(tresp[:template_fields])
                response << tresp
            end
            format_response(response, request.accept)
        end
    end



end
