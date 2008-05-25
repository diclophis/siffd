#!/usr/bin/ruby

require ENV['COMP_ROOT'] + "/siffd"
require ENV['COMP_ROOT'] + "/boot"

fast = Camping::FastCGI.new
fast.mount("/", Siffd)
fast.start
