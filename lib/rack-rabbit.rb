require 'rack-rabbit/server'

module RackRabbit

  #============================================================================
  # CONSTANTS
  #============================================================================

  VERSION = "0.0.1"
  SUMMARY = "A Unicorn-style preforking, rack-based server for hosting RabbitMQ consumer processes"

  #----------------------------------------------------------------------------

  module HEADER
    METHOD           = "Request-Method"
    PATH             = "Request-Path"
    STATUS           = "Status-Code"
    CONTENT_TYPE     = "Content-Type"
    CONTENT_ENCODING = "Content-Encoding"
  end

  #----------------------------------------------------------------------------

  module STATUS
    SUCCESS     = 200     # re-purpose common HTTP status codes
    NOT_FOUND   = 404     # ...
    FAILED      = 500     # ...
  end

  #============================================================================
  # ENTRY POINT
  #============================================================================

  def self.run!(options)
    Server.new(options).run
  end

  #============================================================================
  # HELPER METHODS
  #============================================================================

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

