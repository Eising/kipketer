class Hastighedstest < Sinatra::Base
    # Pings a remote host with one packet
    #
    # @param remote [String] The host to ping
    # @return true or false
    def ping(remote)
        result = system("ping -c 1 -W 1 #{remote} > /dev/null")
        result
    end
end
