class Hastighedstest < Sinatra::Base
    # @!group Reports controller

    # @method get_reports
    # Generate reports
    get '/reports' do
        @pagename = "reports"
        @pagetitle = "Generate Reports"
        @page = params.fetch "page", 1
        @page = @page.to_i
       
        if params[:crid] =~ /(N[A-Z]{2}-\d{6})/i
            atests = Tests.where(:crid => $1.upcase).all
            if atests.count == 0
                flash[:notice] = "No results found."
                redirect to("/reports")
            end
        elsif not params[:crid].nil?
            flash[:notice] = "No results found."
            redirect to("/reports")
        else
            atests = Tests.all
        end
        tests = []
        atests.each do |test| 
            if test.test_results_dataset.count > 0
                tests << test
            end
        end

        p tests
        p tests.class

        @tests = tests.paginate(:page => @page, :per_page => 20)




        haml :'reports/reports'

    end

    # @method get_reports_configure
    # Configure the report for a given id
    # @param id [Integer] the report id to configure
    get '/reports/configure/:id' do
        @pagename = "reports_configure"
        @pagetitle = "Configure Report"
        id = params[:id]
        test = Tests.where(:id => id)
            
        if test.count == 0
            raise Sinatra::NotFound
        else
            @test = test.first
        end
        if params[:remote]
            backbone_template = @test.form.backbone_template.contents_deconfigure
            cpe_template = @test.form.cpe_template.contents_deconfigure
            # Load template values
            template_fields = JSON.parse(@test.template_fields)
            # Find the pair entry
            pairs = settings.pairs
            pair = pairs.select { |x| x["remote"] == params[:remote] }.first
            # add defaults to the two hashes
            template_fields[:testcpe] = pair["cpe"]
            template_fields[:testbb] = pair["bb"]
            template_fields[:pairlocal] = pair["local"]
            template_fields[:pairremote] = pair["remote"]
            if pair.has_key? "netlocal"
                template_fields[:netlocal] = pair["netlocal"]
                template_fields[:netremote] = pair["netremote"]
            end
            @backbone_config = Mustache.render(backbone_template, template_fields)
            @cpe_config = Mustache.render(cpe_template, template_fields)

        end
        haml :'reports/configure'
    end

    # @method post_reports_view
    # Views a report
    # @note This is supposed to be run through pdfkit as view.pdf
    post '/reports/view' do
        # This meant to be run with pdfkit as view.pdf
        test = Tests.where(:id => params[:test_id])
        passed = true
        if test.count == 0
            # Raise an exception if the Test ID isn't in the DB
            raise Sinatra::NotFound
        else
            @test = test.first
        end
        if params[:rtt_test_id]
            @rtt_test = true
            @rtt = JSON.parse(Results.where(:id => params[:rtt_test_id]).first.results)
        end
        if params[:be_test_id]
            @be_test = true
            @be_test_id = params[:be_test_id]
            @be_result = Results.where(:id => @be_test_id).first
            @be = get_thrulay_results(@be_result.results)
            @be_passed = validate_thrulay_results(@be_test_id, 80)
            if @be_passed == false
                passed = false
            end
        end
        if params[:ef_test_id]
            @ef_test = true
            @ef_test_id = params[:ef_test_id]
            @ef_result = Results.where(:id => @ef_test_id).first
            @ef = get_thrulay_results(@ef_result.results)
            @ef_passed = validate_thrulay_results(@ef_test_id, 28)
            if @ef_passed == false
                passed = false
            end
        end
        # Delete the request
        if params[:delete] == "true" and passed
            test.update(:rfs => true) 
        end

        haml :'reports/view', :layout => false
    end

    # @method get_reports_auto_id
    # Autoconfigures and displays a report
    # @note This is meant to be run through pdfkit by adding .pdf after the id
    # @param id [Integer] Id to view, suffix .pdf to view as pdf
    get '/reports/auto/:id' do
        # This meant to be run with pdfkit as view.pdf
        test = Tests.where(:id => params[:id])
        if test.count == 0
            # Raise an exception if the Test ID isn't in the DB
            raise Sinatra::NotFound
        else
            @test = test.first
        end
        external_ds =  @test.test_results_dataset.where(:test_type => "external")
        if external_ds.count > 0
            if env['REQUEST_PATH'] =~ /\.pdf$/
                new_path = env['REQUEST_PATH'].gsub(/\.pdf$/, '')
                redirect to(new_path)
            end
            result = external_ds.last
            res = JSON.parse(result.results)
            test = result.test
            file = res["path"]
            test = result.test
            Tests.where(:id => test.id).update(:rfs => true)
            tempfile = Tempfile.new(test.crid)
            kit = PDFKit.new("#{request.base_url}/internal/reports/manual/#{test.id}", :page_size => 'A4', :print_media_type => true)
            report = kit.to_pdf
            pdf = CombinePDF.new
            pdf << CombinePDF.parse(report)
            pdf << CombinePDF.parse(File.read("./#{file}"))
            pdf.save(tempfile.path)
            content_type 'application/pdf'
            File.read(tempfile.path)
        else

            rtt_ds = @test.test_results_dataset.where(:test_type => "rtt")        
            if rtt_ds.count > 0
                @rtt = JSON.parse(rtt_ds.last.results)
                @rtt_test = true
                @rtt_passed = verify_owamp(@rtt)
                
            end
            be_ds = @test.test_results_dataset.where(:test_type => "be")
            if be_ds.count > 0
                @be_result = be_ds.last
                @be_test_id = @be_result.id
                @be = get_thrulay_results(be_ds.last.results)
                @be_test = true
                @be_passed = validate_thrulay_results(be_ds.last.id, 80)
            end
            ef_ds = @test.test_results_dataset.where(:test_type => "ef")
            if ef_ds.count > 0
                @ef_result = ef_ds.last
                @ef_test_id = @ef_result.id
                @ef_test = true
                @ef = get_thrulay_results(ef_ds.last.results)
                @ef_passed = validate_thrulay_results(ef_ds.last.id, 28)
            end
            passed = true
            passed = false if @rtt_test and not @rtt_passed
            passed = false if @be_test and not @be_passed
            passed = false if @ef_test and not @ef_passed
            if passed
                test.update(:rfs => true)
                haml :'reports/view', :layout => false
            else
                haml :'reports/fail', :layout => false
            end
        end


    end

    # @method post_reports_merge
    # Merges a report with an external report
    post '/reports/merge' do
        result_id = params[:result_id]
        result = Results.where(:id => result_id)
        if not result.count == 1
            $stderr.puts "result #{params[:test_id]} not found"
            halt(404)
        end
        result = result.last
        res = JSON.parse(result.results)
        file = res["path"]
        test = result.test
        if params[:delete] == "true"
            Tests.where(:id => test.id).update(:rfs => true)
        end
        tempfile = Tempfile.new(test.crid)
        kit = PDFKit.new("#{request.base_url}/internal/reports/manual/#{test.id}", :page_size => 'A4', :print_media_type => true)
        report = kit.to_pdf
        pdf = CombinePDF.new
        pdf << CombinePDF.parse(report)
        pdf << CombinePDF.parse(File.read("./#{file}"))
        pdf.save(tempfile.path)
        content_type 'application/pdf'
        File.read(tempfile.path)
    end




    get '/internal/reports/manual/:id' do
        # This is an internal URL
        test = Tests.where(:id => params[:id])
        if test.count == 0
            # Raise an exception if the Test ID isn't in the DB
            raise Sinatra::NotFound
        else
            @test = test.first
        end
        haml :'reports/manual', :layout => false
    end


            


end
