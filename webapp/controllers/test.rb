require 'tempfile'
class Hastighedstest < Sinatra::Base
    # @!group Test controller

    # @method get_test_run_id
    # Runs a specific test
    get '/test/run/:id' do
        @pagename = "test_run"
        @pagetitle = "Run test"
        
        id = params[:id]

        @test = Tests.where(:id => id).first
        @template_fields = JSON.parse(@test.template_fields)
        if @test.form.name =~ /L3POI/
            @pairs = []
            settings.pairs.each do |pair|
                if pair["l3"]
                    @pairs << pair
                end
            end
        else
            @pairs = settings.pairs
        end
        @test_id = id

        haml :'test/run'

    end

    # @method post_test_config
    # Configure test
    post '/test/config' do
        @pagename = "test_config"
        @pagetitle = "Configure test"
        @measurements = params[:tests]
        @measurements << "report"
        @measurements.unshift "verify"

        id = params[:test_id]

        test = Tests.where(:id => id).first
        
        # Load templates
        backbone_template = test.form.backbone_template.contents
        cpe_template = test.form.cpe_template.contents
        # Load template values
        template_fields = JSON.parse(test.template_fields)
        
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
        # BO names
        if template_fields.has_key? "bo_CPE__CPEIP"
            @mgmtcpe = template_fields["bo_CPE__CPEIP"]
        end
        if template_fields.has_key? "bo_LocationB_DeviceName"
            @bbnode = template_fields["bo_LocationB_DeviceName"]
        end
        if template_fields.has_key? "bo_CPE__Router2_DeviceName"
            @bbnode = "Two routers"
        end

        if template_fields.has_key? "mgmtcpe"
            @mgmtcpe = template_fields["mgmtcpe"]
        end
        if template_fields.has_key? "bbnode"
            @bbnode = template_fields["bbnode"]
        end


        # Compile configs
        @backbone_config = Mustache.render(backbone_template, template_fields)
        @cpe_config = Mustache.render(cpe_template, template_fields)
        @remote = pair["remote"]
        @test_id = id
        @params = params

        haml :'test/config'

    end

    # @method get_test_verify_json
    # Verify reachability of the remote ip
    # @param ip [String] IP address to test
    # @return JSON hash 
    get '/test/verify.json/:ip' do
        content_type :json
        if params[:ip] =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/
            ip = params[:ip]
        else
            raise Sinatra::NotFound
        end
        if ping(ip)
            { :ip => ip, :response => "ok"}.to_json
        else
            { :ip => ip, :response => "fail"}.to_json
        end
    end


        
    # @method get_stoptest
    # Stops a test with a given tag
    # @param tag [String] Tag of the test to stop
    get '/stoptest/:tag' do
        if params[:tag]
            @process = Processes.where(:tag => params[:tag]).update(:status => "stopped")
        end
        haml :'test/stop'
    end        

    # @method get_stoptest_json
    # Stops a test with a given tag
    # @param tag [String] Tag of the test to stop
    # @note unsure if this is still in use
    get '/stoptest.json/:tag' do
        if params[:tag]
            pr = Processes.where(:tag => params[:tag]).update(:status => "stopped")
            p pr
        end
        haml :'test/stop'
    end

    # @method get_runtest_json
    # Starts the thrulay test
    # @param test_id [Integer] the ID of the test
    # @param type [String] the test type, either be or ef
    # @param protocol [String] the protocol, tcp or udp
    # @param speed [Integer] The bandwidth to test for (UDP only)
    # @param sessions [Integer] Number of parallel TCP sessions
    # @param tcpwindowsize [Integer] TCP Window Size
    # @param blocksize [Integer] Thrulay block size
    get '/runtest.json' do
        content_type :json
        test_id = params[:test_id]
        remote = params[:remote]
        type = params[:testtype]
        protocol = params[:protocol]
        speed = params[:speed].to_i
        sessions = params[:sessions]
        tcpwindowsize = params[:tcpwindowsize]
        blocksize = params[:blocksize]
        options = { :tcpwindowsize => tcpwindowsize, :sessions => sessions, :blocksize => blocksize }
        tag = params[:tag]
        content_type :json
        if type == "be"
            time = settings.testoptions["duration"]["be"]
            dscp = 0
        else
            time = settings.testoptions["duration"]["ef"]
            dscp = 46
        end
        if protocol == "tcp"
            $status = :running
            Processes.create(:status => "running", :tag => params[:tag])
            id = run_tcp_test(tag, test_id, remote, time, dscp, options)
        elsif protocol == "udp"
            $status = :running
            Processes.create(:status => "running", :tag => params[:tag])
            id = run_udp_test(tag, test_id, remote, time, speed, dscp)
        end

        { "status" => "success", "id" => id }.to_json


    end

    # @method post_test_results
    # Initiates test
    post '/test/result' do
        @opts = params
        @pagename = "test_result"
        @pagetitle = "Running test"
        @tag = Time.now.to_i

        haml :'test/result'
    end

    # @method get_test_delay
    # Runs owping and shows the results
    get '/test/delay' do
        remote = params[:remote]
        test_id = params[:test_id]
        if test_id =~ /^\d+$/ and Tests.where(:id => test_id).count == 1
            test_results = run_owamp(remote)

            res = Results.create(:test_id => test_id, :test_type => "rtt", :results => test_results.to_json, :timestamp => Time.now)

            # Write output
            output = "<h3>RTT A-B</h3>\n<label>Delay minimum/median/max</label><br />\n"
            output += "#{test_results[:local][:min]}/#{test_results[:local][:median]}/#{test_results[:local][:max]} ms<br />\n"
            output += "<label>One-way Jitter</label><br />\n"
            output += "#{test_results[:local][:jitter]} ms<br />\n"
            output += "<label>Packet loss</label><br />\n"
            output += "#{test_results[:local][:loss]}<br />"
            output += "<h3>RTT B-A</h3>\n<label>Delay minimum/median/max</label><br />\n"
            output += "#{test_results[:remote][:min]}/#{test_results[:remote][:median]}/#{test_results[:remote][:max]} ms<br />\n"
            output += "<label>One-way Jitter</label><br />\n"
            output += "#{test_results[:remote][:jitter]} ms<br />\n"
            output += "<label>Packet loss</label><br />\n"
            output += "#{test_results[:remote][:loss]}<br />"
            (verified, errors) = verify_owamp(test_results, true)
            if not verified
                output += "<span class=\"error\">This test failed. Click next to run the test again, or  <a href=\"/test/deprovision/#{@test_id}?remote=#{@remote}\">deprovision the test</a>.</span>\n"
                output += "<h3>Errors:</h3>\n"
                output += "<ul>\n"
                errors.each do |error|
                    output += "<li>#{error}</li>\n"
                end
                output += "</ul><br />\n"
            end


            output
        else
            raise Sinatra::NotFound
        end
    end

    # @method get_test_setup
    # Page that sets up the next test and validates test results
    get '/test/setup' do
        id = params[:test_id]
        @test_id = id
        @remote = params[:remote]
        @test = Tests.where(:id => id).first
        @config = settings.testoptions
        if params[:last_test] =~ /^(be|ef)$/
            result = @test.test_results_dataset.where(:test_type => params[:last_test]).last
            speed = @test.speed
            if params[:last_test] == "ef"
                percentage = 24
            else
                percentage = 80
            end
            validated = validate_thrulay_results(result.id, percentage)
        elsif params[:last_test] == "rtt"
            result = @test.test_results_dataset.where(:test_type => params[:last_test]).last
            validated = verify_owamp(JSON.parse(result.results))
        else
            validated = true
        end
        if validated 
            @measurements = params[:next].split(',')
            @measure = @measurements.shift
        else
            result.delete
            @error = "The last test was not passed. Run the test again, or <a href=\"/test/deprovision/#{@test_id}?remote=#{@remote}\">deprovision the test</a>."
            @measure = params[:last_test]
            @measurements = params[:next].split(',')
        end


        case @measure
        when "verify"
            @pagetitle = "Verifying connectivity"
            @pagename = "test_verify"
            haml :'test/verify'
        when "rtt"
            @pagetitle = "Running delay test"
            @pagename = "test_delay"
            haml :'test/delay'
        when "report"
            redirect to("/reports/configure/#{id}?remote=#{@remote}")
        when /^(be|ef)$/
            @pagetitle = "Set up test"
            @pagename = "test_setup"
            @testtype = @measure
            haml :'test/setup'
        else
            raise Sinatra::NotFound
        end
    end

    # @method get_test_graph_json
    # Function to fetch stored graph data as JSON
    get '/test/graph.json/:id' do
        content_type :json
        result = Results.where(:id => params[:id])
        if result.count == 0
            raise Sinatra::NotFound
        else
            result.first.results
        end
    end

    # @method get_test_saveimage
    # This function finds the latest graph of a specific type, with no image data, reloads that graph and tries to save the image
    get '/test/saveimage/:id' do
        @pagename = "test_saveimage"
        @pagetitle = "Save graph image"
        testds = Tests.where(:id => params[:id])
        halt(404) unless testds.count == 1
        halt(404) unless params[:test_type] =~ /^(be|ef)$/
        halt(404) unless params[:next]
        halt(404) unless params[:remote]
        resultds = testds.first.test_results_dataset.where(:test_type => params[:test_type], :image => nil)
        halt(404) if resultds.count == 0
        @result = resultds.last
        @next = params[:next]
        @remote = params[:remote]

        haml :'test/saveimage'
    end

    # @method get_test_tagstatus_json
    # Returns the status for a given tag
    get '/test/tagstatus.json/:tag' do
        content_type :json
        process = Processes.where(:tag => params[:tag])
        halt(404) if process.count == 0 
        { :tag => params[:tag], :statustext => process.first.status }.to_json
    end

    # @method post_test_saveimage
    # Saves a graph
    post '/test/saveimage' do
        data = params[:data]
        result_id = params[:result_id]

        result = Results.where(:id => result_id)
        if result.count == 0
            raise Sinatra::NotFound
        end
        result.update(:image => data)
        "<b>Successfully inserted image!<b>\n"
    end

    # @method get_test_viewimage
    # views urlencoded image
    get '/test/viewimage/:id' do
        result = Results.where(:id => params[:id])
        if result.count == 0
            raise Sinatra::NotFound
        end
        content_type :"image/png"
        uri = URI::Data.new(result.first.image)
        uri.data
    end

    # @method get_test_deprovision
    # Returns configuration to deconfigure test
    get '/test/deprovision/:id' do
        test = Tests.where(:id => params[:id])
        if test.count == 0
            halt(404)
        end
        test = test.first
        if params[:remote]
            backbone_template = test.form.backbone_template.contents_deconfigure
            cpe_template = test.form.cpe_template.contents_deconfigure
            # Load template values
            template_fields = JSON.parse(test.template_fields)
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
            haml :'test/deprovision'
        else
            halt(404)
        end
            
    end

    # @method get_test_upload
    # Upload an external PDF report to merge with report
    get '/test/upload/:id' do
        # Upload PDF to merge with report
        @pagename = "test_upload"
        @pagetitle = "Upload custom Report"
        
        tests = Tests.exclude(:deleted => true).exclude(:rfs => true).where(:id => params[:id])
        if not tests.count == 1
            halt(404)
        end
        @test = tests.first

        haml :'test/upload'
        
    end

    # @method post_test_upload
    # Upload function
    post '/test/upload' do
        test_id = params[:test_id]
        test = Tests.where(:id => test_id)
        if not test.count == 1
            halt 404
        end
        test = test.first
        destination = "files/report_#{test.crid}_test_#{test_id}.pdf"
        file = params[:file][:tempfile]
        File.open("./#{destination}", "wb") do |f|
            f.write(file.read)
        end
        Results.create(:test_id => test_id, :test_type => "external", :results => { "path" => destination, "filename" => params[:file][:filename] }.to_json, :timestamp => Time.now)
        redirect to("/reports/configure/#{test_id}")
    end
=begin
# old upload routine
    post '/test/upload' do
        test_id = params[:test_id]
        tempfile = Tempfile.new(test_id)
        file = params[:file][:tempfile]
        kit = PDFKit.new("#{request.base_url}/internal/reports/manual/#{test_id}", :page_size => 'A4', :print_media_type => true)
        report = kit.to_pdf
        pdf = CombinePDF.new
        pdf << CombinePDF.parse(report)
        pdf << CombinePDF.parse(File.read(file))
        pdf.save(tempfile.path)
        content_type 'application/pdf'
        File.read(tempfile.path)
    end
=end

end
