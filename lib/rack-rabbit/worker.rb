require 'rack-rabbit/signals'
require 'rack-rabbit/handler'

module RackRabbit
  class Worker

    #--------------------------------------------------------------------------

    attr_reader :config,   # provided by the Server
                :logger,   # convenience for config.logger
                :signals,  # blocking Q for signal handling
                :lock,     # mutex to synchronise with Handler#subscribe for graceful QUIT handling
                :handler   # actually does the work of subscribing to the rabbit Q and handling requests

    #--------------------------------------------------------------------------

    def initialize(config, app)
      @config  = config
      @logger  = config.logger
      @signals = Signals.new
      @lock    = Mutex.new
      @handler = Handler.new(app, config, lock)
    end

    #--------------------------------------------------------------------------

    def run

      logger.info "STARTED a new worker with PID #{Process.pid}"

      trap_signals

      handler.subscribe

      while true
        sig = signals.pop   # BLOCKS until there is a signal
        case sig
        when :INT  then shutdown(:INT)
        when :QUIT then shutdown(:QUIT)
        when :TERM then shutdown(:TERM)
        else
          raise RuntimeError, "unknown signal #{sig}"
        end
      end

    ensure
      handler.unsubscribe

    end

    #--------------------------------------------------------------------------

    def shutdown(sig)
      lock.lock if sig == :QUIT # graceful shutdown should wait for any pending message handler to finish
      logger.info "#{RackRabbit.friendly_signal(sig)} worker #{Process.pid}"
      exit
    end

    #--------------------------------------------------------------------------

    def trap_signals  # overwrite the handlers inherited from the server process

      [:QUIT, :TERM, :INT].each do |sig|
        trap(sig) do
          signals.push(sig)
        end
      end

      trap(:CHLD, :DEFAULT)
      trap(:TTIN, nil)
      trap(:TTOU, nil)

    end

    #--------------------------------------------------------------------------

  end
end
