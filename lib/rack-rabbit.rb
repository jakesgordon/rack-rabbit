require 'rack-rabbit/server'

module RackRabbit

  VERSION = "0.0.1"
  SUMMARY = "A Unicorn-style preforking, rack-based server for hosting RabbitMQ consumer processes"

  def self.run!(options)
    Server.new(options).run
  end

end

