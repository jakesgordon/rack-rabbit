#!/usr/bin/env ruby
# encoding: utf-8
#
# Lightweight executable for using RackRabbit::Client to access a RackRabbit server
#
# TODO: extend to support additional patterns
#
#  - Worker (ENQUEUE)
#  - Pub/Sub (PUBLISH)
#

require "optparse"

require "rack-rabbit"
require "rack-rabbit/client"

action  = :execute
options = {
  :queue  => "rack-rabbit",
  :method => nil,
  :path   => nil,
  :body   => nil
}

queue_help   = "specify the queue to publish the message (default: rack-rabbit)"
method_help  = "specify the method used to publish the message (default: GET)"
path_help    = "specify the path of the message (default '')"
body_help    = "specify the body of the message (default '')"
adapter_help = "specify an alternate rabbit client gem (default: bunny)"

op = OptionParser.new
op.banner = "Make requests to rabbitMQ consumer processes"
op.separator "Usage: rr [options] [METHOD] [PATH] [BODY]"
op.separator ""

op.on("-h", "--help")                          { action = :help    }
op.on("-v", "--version")                       { action = :version }
op.on("-q", "--queue QUEUE",   queue_help)     { |value| options[:queue]   = value                      }
op.on("-m", "--method METHOD", method_help)    { |value| options[:method]  = value.to_s.upcase.to_sym   }
op.on("-p", "--path PATH",     path_help)      { |value| options[:path]    = value                      }
op.on("-b", "--body BODY",     body_help)      { |value| options[:body]    = value                      }
op.on("-a", "--adapter ADAPTER", adapter_help) { |value| options[:adapter] = value.to_s.downcase.to_sym }
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

def execute(options)
  puts RackRabbit::Client.request(options[:queue],
                                  options[:method],
                                  options[:path],
                                  options[:body])
end

case action
when :help    then puts op.to_s
when :version then puts RackRabbit::VERSION
else

  if options[:adapter] == :amqp        # then need a running EventMachine reactor...
    require 'eventmachine'
    EventMachine.run do
      EventMachine.defer do   # ... but don't block the reactor
        execute(options)
        EventMachine.stop
      end
    end
  else                        # otherwise just run directly on main thread
    execute(options)
  end

end
