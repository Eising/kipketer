FROM ubuntu:latest
MAINTAINER Gabriel Glachant <gglachant@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

#RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN apt-get -qy update && apt-get -qy install apt-utils ca-certificates curl git-core sudo ruby ruby-dev libmysqlclient-dev ruby-libxml build-essential libssl-dev libsqlite3-dev ntp libfontconfig1 && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

RUN locale-gen  en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8
RUN service ntp start
# Install thrulay
RUN curl -O http://softlayer-ams.dl.sourceforge.net/project/thrulay-ng/thrulay-ng/0.6.2/thrulay-ng-0.6.2.tar.gz && tar zxvf thrulay-ng-0.6.2.tar.gz && cd thrulay-ng-0.6.2 && ./configure && make && make install 
# Install owampd
RUN cd && curl -O http://software.internet2.edu/sources/owamp/owamp-3.3.tar.gz && tar zxvf owamp-3.3.tar.gz && cd owamp-3.3 && ./configure && make && make install \
&& mkdir /etc/owamp \
&& echo "authmode O\ndatadir /usr/local/share/owamp\ngroup owamp\nuser owamp\nvardir /var/run" > /etc/owamp/owampd.conf \
&& groupadd -r owamp \
&& useradd -r -g owamp owamp \
&& mkdir /usr/local/share/owamp \
&& chown owamp:owamp /usr/local/share/owamp
RUN mkdir /opt/app
RUN gem install bundler
RUN gem install rake
WORKDIR /opt/app
ADD Gemfile /opt/app/Gemfile
ADD Gemfile.lock /opt/app/Gemfile.lock
RUN bundle install
EXPOSE 5000
