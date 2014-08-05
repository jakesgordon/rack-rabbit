module RackRabbit
  class Worker

    #--------------------------------------------------------------------------

    attr_reader :server,
                :config,
                :logger,
                :app

    def initialize(server, app)
      @server = server
      @config = server.config
      @logger = server.logger
      @app    = app
    end

    #--------------------------------------------------------------------------

    def run
      logger.info "RUNNING"
      trap_signals
      while true
        sleep 10 # TODO: implement rabbit subscribe queue
      end
    end

    #--------------------------------------------------------------------------

    def trap_signals

      [:QUIT, :TERM, :INT].each do |sig|
        trap(sig) do
          # DIRTY HACK - can't use Logger during trap because it uses a mutex (https://bugs.ruby-lang.org/issues/7917)
          #            - do it in a thread instead (and wait for thread to finish before exiting)
          #            - THIS IS ALL SORTS OF BAD (deadlockable)
          #            - so TODO - refactor worker to use a signal Q (like server) to allow us to log and exit at a more leisurely pace
          tr = Thread.new{ logger.info sig }
          tr.join
          exit
        end
      end

      [:CHLD, :TTIN, :TTOU].each do |sig|
        trap(sig, :DEFAULT)
      end

    end

    #==========================================================================

  end
end
