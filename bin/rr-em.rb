#!/usr/bin/env ruby
# encoding: utf-8
#
# TEMPORARY HACK client script for testing RackRabbit::Client in an EventMachine host
#

$LOAD_PATH.push File.expand_path("../lib", File.dirname(__FILE__)) # TODO: shouldn't need this

require 'eventmachine'
require "rack-rabbit/client"

EventMachine.run do

  EventMachine.defer do # don't block main thread
    client   = RackRabbit::Client.new(:adapter => :amqp)
    queue    = "rpc"
    path     = ARGV[0]
    response = client.get(queue, path)
    puts response
    client.disconnect
    EventMachine.stop
  end

end
