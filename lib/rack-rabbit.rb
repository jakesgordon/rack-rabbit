require 'rack-rabbit/server'

module RackRabbit

  #----------------------------------------------------------------------------

  VERSION = "0.0.1"
  SUMMARY = "A Unicorn-style preforking, rack-based server for hosting RabbitMQ consumer processes"

  #----------------------------------------------------------------------------

  def self.run!(options)
    Server.new(options).run
  end

  #----------------------------------------------------------------------------
  # HELPER METHODS
  #----------------------------------------------------------------------------

  def self.friendly_signal(sig)
    case sig
    when :QUIT then "QUIT"
    when :INT  then "INTERRUPT"
    when :TERM then "TERMINATE"
    else
      sig
    end
  end

  #----------------------------------------------------------------------------

end

