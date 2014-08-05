require 'rack/builder'
require 'rack/server'

require 'rack-rabbit/config'

module RackRabbit
  class Server

    attr_reader :app,
                :config,
                :logger

    def initialize(rackup, options)
      @config = Config.new(rackup, options)
      @logger = config.logger
    end

    def run
      load_app
      logger.info "RUNNING #{app} (#{config.rackup})"
      logger.info " ... coming soon!"
    end

    def load_app
      @app, options = Rack::Builder.parse_file(config.rackup)
    end

  end
end
