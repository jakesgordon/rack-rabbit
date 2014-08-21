require 'rack/builder'
require 'rack/server'

require 'rack-rabbit'
require 'rack-rabbit/config'
require 'rack-rabbit/signals'
require 'rack-rabbit/worker'
require 'rack-rabbit/middleware/program_name'

module RackRabbit
  class Server

    #--------------------------------------------------------------------------

    attr_reader :app,
                :config,
                :logger,
                :server_pid,
                :worker_pids,
                :killed_pids,
                :signals

    def initialize(options)
      @config       = Config.new(options)
      @logger       = config.logger
      @server_pid   = $$
      @worker_pids  = []
      @killed_pids  = []
      @signals      = Signals.new
    end

    #--------------------------------------------------------------------------

    def run

      check_pid

      if config.daemonize
        daemonize
      elsif config.logfile
        redirect_output
      end

      write_pid

      logger.info "RUNNING #{config.app_id} (#{config.rack_file}) #{'DAEMONIZED' if config.daemonize}"
      logger.info "  rabbit  : #{config.rabbit}"
      logger.info "  queue   : #{config.queue}"
      logger.info "  workers : #{config.workers}"
      logger.info "  preload : true"              if config.preload_app
      logger.info "  logfile : #{config.logfile}" unless config.logfile.nil?
      logger.info "  pidfile : #{config.pidfile}" unless config.pidfile.nil?

      load_app if config.preload_app

      trap_server_signals
      manage_workers

    end

    #--------------------------------------------------------------------------

    def manage_workers
      while true

        maintain_worker_count

        sig = signals.pop   # BLOCKS until there is a signal
        case sig

        when :INT  then shutdown(:INT)
        when :QUIT then shutdown(:QUIT)
        when :TERM then shutdown(:TERM)

        when :HUP
          reload

        when :CHLD
          reap_workers

        when :TTIN
          config.workers [config.max_workers, config.workers + 1].min

        when :TTOU
          config.workers [config.min_workers, config.workers - 1].max

        else
          raise RuntimeError, "unknown signal #{sig}"

        end

      end
    end

    #--------------------------------------------------------------------------

    def reload
      logger.info "RELOADING"
      config.reload
      load_app if config.preload_app
      kill_all_workers(:QUIT)  # they will respawn automatically
    end

    def maintain_worker_count
      unless shutting_down?
        diff = worker_pids.length - config.workers
        if diff > 0
          diff.times { kill_random_worker(:QUIT) }
        elsif diff < 0
          (-diff).times { spawn_worker }
        end
      end
    end

    def spawn_worker
      config.before_fork(self)
      worker_pids << fork do
        signals.close
        load_app unless config.preload_app
        worker = Worker.new(config, app)
        config.after_fork(self, worker)
        worker.run
      end
    end

    def kill_random_worker(sig)
      kill_worker(sig, worker_pids.sample) # choose a random wpid
    end

    def kill_all_workers(sig)
      kill_worker(sig, worker_pids.last) until worker_pids.empty?
    end

    def kill_worker(sig, wpid)
      worker_pids.delete(wpid)
      killed_pids.push(wpid)
      Process.kill(sig, wpid)
    end

    def reap_workers
      while true
        wpid = Process.waitpid(-1, Process::WNOHANG)
        return if wpid.nil?
        worker_pids.delete(wpid)
        killed_pids.delete(wpid)
      end
      rescue Errno::ECHILD
    end

    #--------------------------------------------------------------------------

    def shutdown(sig)
      @shutting_down = true
      kill_all_workers(sig)
      Process.waitall
      logger.info "#{RackRabbit.friendly_signal(sig)} server"
      exit
    end

    def shutting_down?
      @shutting_down
    end

    #==========================================================================
    # DAEMONIZING, PID MANAGEMENT, and OUTPUT REDIRECTION
    #==========================================================================

    def daemonize
      exit if fork
      Process.setsid
      exit if fork
      Dir.chdir "/"
      redirect_output
      logger.master_pid = $$ if logger.respond_to?(:master_pid)  # inform logger of new master_pid so it can continue to distinguish between "SERVER" and "worker" in log preamble
    end

    def redirect_output
      if logfile = config.logfile
        logfile = File.expand_path(logfile)
        FileUtils.mkdir_p(File.dirname(logfile), :mode => 0755)
        FileUtils.touch logfile
        File.chmod(0644, logfile)
        $stderr.reopen(logfile, 'a')
        $stdout.reopen($stderr)
        $stdout.sync = $stderr.sync = true
      else
        $stderr.reopen('/dev/null', 'a')
        $stdout.reopen($stderr)
      end
    end

    def write_pid
      pidfile = config.pidfile
      if pidfile
        begin
          File.open(pidfile, ::File::CREAT | ::File::EXCL | ::File::WRONLY){|f| f.write("#{Process.pid}") }
          at_exit { File.delete(pidfile) if File.exists?(pidfile) }
        rescue Errno::EEXIST
          check_pid
          retry
        end
      end
    end

    def check_pid
      pidfile = config.pidfile
      if pidfile
        case pid_status(pidfile)
        when :running, :not_owned
          logger.fatal "A server is already running. Check #{pidfile}"
          exit(1)
        when :dead
          File.delete(pidfile)
        end
      end
    end

    def pid_status(pidfile)
      return :exited unless File.exists?(pidfile)
      pid = ::File.read(pidfile).to_i
      return :dead if pid == 0
      Process.kill(0, pid)
      :running
    rescue Errno::ESRCH
      :dead
    rescue Errno::EPERM
      :not_owned
    end

    #==========================================================================
    # SIGNAL HANDLING
    #==========================================================================

    def trap_server_signals

      [:HUP, :INT, :QUIT, :TERM, :CHLD, :TTIN, :TTOU].each do |sig|
        trap(sig) do
          signals.push(sig)
        end
      end

    end

    #==========================================================================
    # RACK APP HANDLING
    #==========================================================================

    def load_app
      inner_app, options = Rack::Builder.parse_file(config.rack_file)
      @app = Rack::Builder.new do
        use RackRabbit::Middleware::ProgramName
        run inner_app
      end.to_app
      logger.info "LOADED #{inner_app.name} FROM #{config.rack_file}"
      @app
    end

    #--------------------------------------------------------------------------

  end
end
