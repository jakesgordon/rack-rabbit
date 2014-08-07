require 'rack/builder'
require 'rack/server'

require 'rack-rabbit/config'
require 'rack-rabbit/signals'
require 'rack-rabbit/worker'

module RackRabbit
  class Server

    #--------------------------------------------------------------------------

    attr_reader :app,
                :config,
                :logger,
                :server_pid,
                :worker_pids,
                :fired_pids,
                :worker_count,
                :signals

    def initialize(options)
      @config       = Config.new(options)
      @logger       = config.logger
      @server_pid   = $$
      @worker_pids  = []
      @fired_pids   = []
      @worker_count = config.workers
      @signals      = Signals.new
    end

    #--------------------------------------------------------------------------

    def run
      trap_server_signals
      load_app
      logger.info "RUNNING #{app} (#{config.rackup}) for queue #{config.queue}"
      maintain_worker_count
      manage_workers
    end

    #--------------------------------------------------------------------------

    def manage_workers
      while true

        sig = signals.pop   # BLOCKS until there is a signal
        case sig

        when :INT  then shutdown(:INT)
        when :QUIT then shutdown(:QUIT)
        when :TERM then shutdown(:TERM)

        when :CHLD
          reap_workers

        when :TTIN
          @worker_count = [config.max_workers, worker_count + 1].min

        when :TTOU
          @worker_count = [config.min_workers, worker_count - 1].max

        else
          raise RuntimeError, "unknown signal #{sig}"

        end

        maintain_worker_count

      end
    end

    #--------------------------------------------------------------------------

    def maintain_worker_count
      unless shutting_down?
        diff = worker_pids.length - worker_count
        if diff > 0
          diff.times { fire_random_worker }
        elsif diff < 0
          (-diff).times { spawn_worker }
        end
      end
    end

    def spawn_worker
      worker_pids << fork do
        trap_worker_signals
        signals.close
        Worker.new(self, app).run
      end
    end

    def fire_random_worker
      wpid = worker_pids.sample   # choose a random wpid
      worker_pids.delete(wpid)
      fired_pids.push(wpid)
      Process.kill(:QUIT, wpid)
    end

    def kill_workers(sig)
      worker_pids.each {|wpid| Process.kill(sig, wpid)}
    end

    def reap_workers
      while true
        wpid = Process.waitpid(-1, Process::WNOHANG)
        return if wpid.nil?
        worker_pids.delete(wpid)
        fired_pids.delete(wpid)
      end
      rescue Errno::ECHILD
    end

    #--------------------------------------------------------------------------

    def shutdown(sig)
      logger.info "SHUTDOWN (#{sig})"
      @shutting_down = true
      kill_workers(sig)
      Process.waitall
      exit
    end

    def shutting_down?
      @shutting_down
    end

    #==========================================================================
    # SIGNAL HANDLING
    #==========================================================================

    def trap_server_signals

      [:INT, :QUIT, :TERM, :CHLD, :TTIN, :TTOU].each do |sig|
        trap(sig) do
          signals.push(sig)
        end
      end

    end

    #--------------------------------------------------------------------------

    def trap_worker_signals

      [:QUIT, :TERM, :INT].each do |sig|
        trap(sig) do
          exit
        end
      end

      [:CHLD].each do |sig|
        trap(sig, :DEFAULT)
      end

      [:TTIN, :TTOU].each do |sig|
        trap(sig, nil)
      end

    end

    #==========================================================================
    # RACK APP HANDLING
    #==========================================================================

    def load_app
      @app, options = Rack::Builder.parse_file(config.rackup)
    end

    #--------------------------------------------------------------------------

  end
end
