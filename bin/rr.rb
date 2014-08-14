#!/usr/bin/env ruby
# encoding: utf-8
#
# TEMPORARY HACK client script for testing RackRabbit::Client
#
# TODO: extend to support all patterns
#
#  - Req/Response (GET/POST/PUT/HEAD/DELETE)
#  - Worker (ENQUEUE)
#  - Pub/Sub (PUBLISH)
#

require "optparse"
require "rack-rabbit"
require "rack-rabbit/client"

action  = :run
options = {
  :queue  => "rack-rabbit",
  :method => nil,
  :path   => nil,
  :body   => nil
}

queue_help  = "specify the queue to publish the message (default: rack-rabbit)"
method_help = "specify the method used to publish the message (default: GET)"
path_help   = "specify the path of the message (default '')"
body_help   = "specify the body of the message (default '')"
 
op = OptionParser.new
op.banner = "Make requests to rabbitMQ consumer processes"
op.separator "Usage: rr [options] [METHOD] [PATH] [BODY]"
op.separator ""

op.on("-h", "--help")                       { action = :help    }
op.on("-v", "--version")                    { action = :version }
op.on("-q", "--queue QUEUE",   queue_help)  { |value| options[:queue]  = value }
op.on("-m", "--method METHOD", method_help) { |value| options[:method] = value }
op.on("-p", "--path PATH",     path_help)   { |value| options[:path]   = value }
op.on("-b", "--body BODY",     body_help)   { |value| options[:body]   = value }
op.separator ""

op.parse!(ARGV)

if options[:method].nil?
  if options[:method] = RackRabbit.parse_method(ARGV[0], :default => nil)
    ARGV.delete_at(0)
  else
    options[:method] = "GET"
  end
end

options[:path] ||= ARGV.shift
options[:body] ||= ARGV.shift

case action
when :help    then puts op.to_s
when :version then puts RackRabbit::VERSION
else
  puts RackRabbit::Client.request(options[:queue],
                                  options[:method],
                                  options[:path],
                                  options[:body])
end

