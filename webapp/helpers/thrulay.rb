class Hastighedstest < Sinatra::Base
    require 'open3'
    require 'logger'


    # Fork and run child process in block
    #
    # @return a block
    def runfork(ps=false)
        logger = Logger.new(STDERR) # Log everything to STDERR
        logger.debug "Forking: Parent ID = #{Process.pid}"
        DB.disconnect
        child = fork do
            begin
                start = Time.now
                logger.debug "Child PID = #{Process.pid}"
                yield
            rescue => ex
                ps.update(:status => "done") if ps
                logger.error "Child returned an exception: - #{ex.class}: #{ex.message}"
            ensure
                logger.info "Child #{Process.pid} took #{Time.now - start} sec"
                exit!(0)
            end
        end
        Process.detach(child)
        return child

    end

    # Run thrulay in TCP mode
    #
    # @param tag [String] a tag to identify the running test process
    # @param test_id [Integer] the ID of the current test from the DB
    # @param server [String] the IP of the remote thrulayd
    # @param time [Integer] number of seconds to run the test
    # @param dscp [Integer] DiffServ Code Point for the test
    # @param opts [Hash] Options to pass to thrulay
    # @return id of the results table row
    def run_tcp_test(tag, test_id, server, time, dscp=0, opts=nil)
        if dscp == 0
            test_type = "be"
        else
            test_type = "ef"
        end
        ps = Processes.where(:tag => tag)
        raise "No test_id" if test_id.nil?
        config = test_config[:testoptions].first
        if opts
            if opts.has_key? :tcpwindowsize
                windowsize = opts[:tcpwindowsize]
            else
                windowsize = config[:tcpwindowsize]
            end
            if opts.has_key? :sessions
                sessions = opts[:sessions]
            else
                sessions = config[:default_sessions]
            end
            if opts.has_key? :blocksize
                blocksize = opts[:blocksize]
            else
                blocksize = config[:blocksize]
            end
        else
            windowsize = config[:tcpwindowsize]
            sessions = config[:default_sessions]
            blocksize = config[:blocksize]
        end



        thrulay_bin = settings.binaries["thrulay"]
        thrulay_opts = "-D #{dscp} -t #{time} -m #{sessions} -l #{blocksize} -w #{windowsize} #{server}"
        sums = {}
        cur_end = 0

        result = Results.create(:test_id => test_id, :test_type => test_type, :protocol => "tcp")
        # Wrap everything around spork
        runfork(ps) do
            Open3.popen3("#{thrulay_bin} #{thrulay_opts}") do |stdin, stdout, stderr, thread|
                pid = thread.pid
                { :out => stdout, :err => stderr }.each do |key, stream|
                    t = Thread.new do
                        until (raw_line = stream.gets).nil? do
                            if ps.first.status == "stopped"
                                result.delete
                                Process.kill("TERM", pid)
                                Thread.kill(t)
                            end
                            if res = raw_line.match(/\s+\(\s?(\d+)\)\s+(\d+)\.\d+\s+(\d+)\.\d+\s+(\d+\.\d+)/)
                                thread = res[1]
                                bw = res[4]
                                s_end = res[3]

                                if sums.has_key? s_end.to_i
                                    sums[s_end.to_i] += bw.to_f
                                else
                                    sums[s_end.to_i] = bw.to_f
                                end
                                if cur_end != s_end
                                    # Write results to db
                                    result.update(:results => build_results(sums).to_json, :timestamp => Time.now)
                                    cur_end = s_end
                                end


                            end
                        end
                    end
                end
                thread.join
            end

            result.update(:results => build_results(sums).to_json, :timestamp => Time.now)
            ps.update(:status => "done")
        end
        return result.id
    end
    

    # Formats results for graphing
    #
    # @param sums [Hash] x/y values to graph
    # @param done [Bool] whether the test is done
    # @return A Hash that can be graphed
    def build_results(sums, done=nil)
        result = { :label => "Mbit/s", :data => [] }
        sums.each do |k,v|
            result[:data] << [k, v]
        end
        if done
            {:output => result, :done => done}
        else
            {:output => result}
        end
    end

    # Run a udp test
    # @param tag [String] a tag to identify the running test process
    # @param test_id [Integer] the ID of the current test from the DB
    # @param server [String] the IP of the remote thrulayd
    # @param time [Integer] number of seconds to run the test
    # @param speed [Integer] Bandwidth to run the UDP test in. Mbit/s.
    # @param dscp [Integer] DiffServ Code Point for the test.
    # @return id of the results table row
    def run_udp_test(tag, test_id, server, time, speed, dscp=0)
        raise "No test_id" if test_id.nil?
        thrulay_bin = settings.binaries["thrulay"]
        if dscp == 0
            test_type = "be"
        else
            test_type = "ef"
        end

        cur_time = 0

        sums = { }
        result = Results.create(:test_id => test_id, :test_type => test_type, :protocol => "udp")
        process = Processes.where(:tag => tag)

        runfork do
            while cur_time < time
                if time - cur_time < 5
                    ltime = time - cur_time
                else
                    ltime = 5
                end
                if process.first.status == "stopped"
                    result.delete
                    break
                end
                thrulay_opts = "-D #{dscp} -t #{ltime} -u#{speed}M -l 1500 #{server}"
                Open3.popen3("#{thrulay_bin} #{thrulay_opts}") do |stdin, stdout, stderr, thread|
                    { :out => stdout, :err => stderr }.each do |key, stream|
                        Thread.new do
                            until (raw_line = stream.gets).nil? do
                                if res = raw_line.match(/received (\d+) unique packets/)
                                    packets = res[1].to_f
                                    mbps = packets * 1500.0 / ltime.to_f * 8.0 / 1000000.0
                                    cur_time += ltime
                                    sums[cur_time] = mbps
                                    #Update the db
                                end
                            end
                        end
                    end
                    thread.join
                    result.update(:results => build_results(sums).to_json, :timestamp => Time.now)
                end
            end
            result.update(:results => build_results(sums).to_json, :timestamp => Time.now)
            process.update(:status => "done")

        end
        return result.id
    end


end
