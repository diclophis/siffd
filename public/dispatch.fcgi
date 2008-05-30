#!/usr/bin/ruby

require ENV['COMP_ROOT'] + "/siffd"
require ENV['COMP_ROOT'] + "/boot"

Rack::Handler::FastCGI.run((Siffd))
