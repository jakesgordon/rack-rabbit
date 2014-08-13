#!/usr/bin/env ruby
# encoding: utf-8
#
# TEMPORARY HACK client script for testing rack-rabbit hosted servers
#
# TODO: extend to support all patterns
#
#  - Req/Response (GET/POST/PUT/HEAD/DELETE)
#  - Worker (ENQUEUE)
#  - Pub/Sub (PUBLISH)
#

$LOAD_PATH.push File.expand_path("../lib", File.dirname(__FILE__)) # TODO: shouldn't need this

require "rack-rabbit/client"

client = RackRabbit::Client.new

queue    = "rpc"
path     = ARGV[0]
response = client.get(queue, path)

puts response

client.disconnect
