#!/usr/bin/env ruby
# encoding: utf-8
#
# Make requests to a RackRabbit server.
#

#==============================================================================
# PARSE COMMAND LINE OPTIONS
#==============================================================================

require "optparse"

action  = :execute
options = {
  :queue  => "rack-rabbit",
  :method => nil,
  :path   => nil,
  :body   => nil
}

summary      = "Make requests to rabbitMQ consumer processes hosted by a RackRabbit server."
usage        = "Usage:  rr [options] [METHOD] [PATH] [BODY]"
banner       = "#{summary}\n\n#{usage}"
queue_help   = "specify the queue to publish the message (default: rack-rabbit)"
method_help  = "specify the method used to publish the message (default: GET)"
path_help    = "specify the path of the message (default '')"
body_help    = "specify the body of the message (default '')"
adapter_help = "specify an alternate rabbit client gem (default: bunny)"
include_help = "specify an additional $LOAD_PATH (may be used more than once)"

op = OptionParser.new
op.banner = banner

op.separator ""
op.separator "RackRabbit options:"
op.on("-q", "--queue QUEUE",     queue_help)   { |value| options[:queue]   = value                      }
op.on("-m", "--method METHOD",   method_help)  { |value| options[:method]  = value.to_s.upcase.to_sym   }
op.on("-p", "--path PATH",       path_help)    { |value| options[:path]    = value                      }
op.on("-b", "--body BODY",       body_help)    { |value| options[:body]    = value                      }
op.on("-a", "--adapter ADAPTER", adapter_help) { |value| options[:adapter] = value.to_s.downcase.to_sym }

op.separator ""
op.separator "Ruby options:"
op.on("-I", "--include PATH", include_help) { |value| $LOAD_PATH.unshift(*value.split(":")) }

op.separator ""
op.separator "Common options:"
op.on("-h", "--help")    { action = :help    }
op.on("-v", "--version") { action = :version }

op.separator ""
op.parse!(ARGV)

if options[:method].nil?
  if options[:method] = ["GET", "POST", "PUT", "DELETE"].find{|m| m == ARGV[0].to_s.upcase }
    ARGV.delete_at(0)
  else
    options[:method] = :GET
  end
end

options[:path] ||= ARGV.shift
options[:body] ||= ARGV.shift

#==============================================================================
# EXECUTE script (within an EM reactor if necessary)
#==============================================================================

require 'rack-rabbit'
require 'rack-rabbit/client'

module RR

  def self.make_request(options)
    puts RackRabbit::Client.request(options[:queue], options[:method], options[:path], options[:body])
  end

  def self.execute(options)
    if options[:adapter] == :amqp  # then need a running EventMachine reactor...
      require 'eventmachine'
      EventMachine.run do
        EventMachine.defer do      # ... but don't block the reactor
          make_request(options)
          EventMachine.stop
        end
      end
    else                           # otherwise just run directly on main thread
      make_request(options)
    end
  end

end # module RR

case action
when :help    then puts op.to_s
when :version then puts RackRabbit::VERSION
else
  RR.execute(options)
end

#==============================================================================
