module RackRabbit

  #============================================================================
  # CONSTANTS
  #============================================================================

  VERSION = "0.1.0"
  SUMMARY = "A Unicorn-style forking, rack-based server for hosting rabbitMQ consumer processes"

  DEFAULT_RABBIT = {
    :host    => "127.0.0.1",
    :port    => "5672",
    :adapter => "bunny"
  }.freeze

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
    CREATED     = 201     # ...
    ACCEPTED    = 202     # ...
    BAD_REQUEST = 400     # ...
    NOT_FOUND   = 404     # ...
    FAILED      = 500     # ...
  end

  #============================================================================
  # ENTRY POINT
  #============================================================================

  def self.run!(options)
    require 'rack-rabbit/server'
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

