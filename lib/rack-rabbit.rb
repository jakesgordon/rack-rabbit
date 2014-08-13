require 'rack-rabbit/server'

module RackRabbit

  #----------------------------------------------------------------------------

  VERSION = "0.0.1"
  SUMMARY = "A Unicorn-style preforking, rack-based server for hosting RabbitMQ consumer processes"
  METHODS = [ :GET, :POST, :PUT, :DELETE ] # ... and coming soon - ENQUEUE and PUBLISH

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

  def self.parse_method(method, options = {})
    method = method.to_s.upcase.to_sym
    if METHODS.include?(method)
      method
    elsif options.key?(:default)
      options[:default]
    else
      raise ArgumentError, "unknown method #{method} - must be one of #{METHODS.join(', ')}"
    end
  end

  #----------------------------------------------------------------------------

end

