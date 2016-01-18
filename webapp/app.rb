#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"
require "bundler"
require 'yaml'
require 'ipaddr'
require 'will_paginate'
require 'will_paginate/sequel'
require 'will_paginate/array'
require 'will_paginate/view_helpers/sinatra'

# All gem dependencies are handled through bundler
Bundler.require


class Hastighedstest < Sinatra::Base
    Encoding.default_external = Encoding::UTF_8
    Encoding.default_internal = Encoding::UTF_8
    register Sinatra::AssetPack
    register Sinatra::ConfigFile
    helpers WillPaginate::Sinatra::Helpers

    assets do
        js :application, [ 
            '/js/jquery-2.1.1.min.js',
            '/js/jquery.plugin.min.js',
            '/js/jquery.flot.min.js',
            '/js/*.js' 
        ]
        css :application, [ '/css/screen.css', '/css/jquery.datepick.css']
        css :print, [ '/css/print.css' ]
        css :embed, [ '/css/embed.css', '/css/jquery.datepick.css' ]

        js_compression :jsmin
        css_compression :simple
    end
    config_file "etc/config.yml"

    case ENV["RACK_ENV"]
    when "test"
      DB = Sequel.connect("sqlite://db/test.db")
    when "development"
      DB = Sequel.connect("sqlite://db/development.db")
    else
      DB = Sequel.connect("sqlite://db/production.db")
    end

    DB.extension(:pagination)
    set :views, settings.root + '/views'

    # Flash
    enable :sessions
    register Sinatra::Flash
    
    configure :development do
        set :session_secret, "f00ballllllaaar"
    end
    helpers Sinatra::Streaming
end

# Load all helpers

Dir[File.dirname(__FILE__) + "/helpers/*.rb"].each do |file| 
  require file

end

# Load up all models next
Dir[File.dirname(__FILE__) + "/models/*.rb"].each do |file| 
  require file
end

# Load up all controllers last
Dir[File.dirname(__FILE__) + "/controllers/*.rb"].each do |file| 
  require file
end
