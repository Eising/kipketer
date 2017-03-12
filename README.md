[![No Maintenance Intended](http://unmaintained.tech/badge.svg)](http://unmaintained.tech/)

# kipketer
A bandwidth testing platform with a strong templating engine

Kipketer was originally developed for Nianet A/S with the purpose of facilitating line testing on a larger scale.
It is now released under the MIT license excluding certain assets, but in an entirely functional state.

It facilitates the configuration of a loop on a remote CPE, and using this loop initiates and reports on throughput and latency tests.

# Installation

This guide is written for a debian-based linux and requires Ruby 2.3 to be installed through external repositories.

## Architecture

The system requires two servers: A test-initiating server, and a
test-receiving server. The test-initiating server also runs the web service.

The system is designed based around a number test pair addresses that are
looped on the back of a device under test (DUT). In production, this was designed
using two VRFs, each containing unique addresses routed via the DUT.

### routing:

Here the 198.18.0.0/15 network is used for testing. 198.18.0.0/16 belongs to
the first vrf and 198.19.0.0/16 belongs to the second. A number of test-pairs
are configured in the following way:

#### transmit-server
```
ip addr add 198.18.0.2/26 dev eth0
ip addr add 198.18.0.3/26 dev eth0
ip route add 198.19.0.2/32 via 198.18.0.1 dev eth0 source 198.18.0.2
ip route add 198.19.0.3/32 via 198.18.0.1 dev eth0 source 198.18.0.3
```
etc.
#### receive-server
```
ip route add 198.19.0.2/26 dev eth0
ip route add 198.19.0.3/26 dev eth0
ip route add 198.18.0.2/32 via 198.19.0.1 dev eth0 source 198.19.0.2
ip route add 198.18.0.3/32 via 198.19.0.1 dev eth0 source 198.19.0.3
etc.
```

## Required software
### Thrulay-ng
This system requires <a href="http://thrulay-ng.sourceforge.net/">thrulay-ng</a>, available on sourceforge.
Compile it locally and add it to your path

### Ruby
Ruby dependencies are handled through bundler, so make sure it's installed through the ruby gem system

```
gem install bundler
```

### Owamp
OWAMP, as part of the perfsonar suite is also required. Compile it from source also

The required file is available here: http://software.internet2.edu/sources/owamp/owamp-3.3.tar.gz

### NTP
OWAMP requires good time service on both servers, as the difference in clock
accuracy will be source of error in the measurements. Therefore it is
recommended to use proper low-stratum NTP-servers and to use physical servers,
not virtual, to these servers.

## Web service
The system runs using the micro-webserver Puma. It's configured in config/puma.rb to bind to a UNIX socket, and designed to be proxied through nginx.
Refer to the nginx documentation on how to proxy to a unix socket.


# Running through docker

Docker is recommended for local development. It runs with a development
environment that allows local testing.

To run the docker, compile the dockerfile and run the docker.sh file.

The docker.sh file leaves you in a shell, and you must run the following
manually:

```
# thrulayd
# owampd -c /etc/owamp
# service ntp start
# cd /opt/app
# bundle install
# puma -C "-" -p 5000
```
Then you can connect to the docker container ip port 5000
