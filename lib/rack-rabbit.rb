require 'rack-rabbit/server'

module RackRabbit

  VERSION = "0.0.1"
  SUMMARY = "A Unicorn-style preforking, rack-based server for hosting RabbitMQ consumer processes"

  def self.run!(rackup, options)
    Server.new(rackup, options).run
  end

end

