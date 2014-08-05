require 'rack/builder'
require 'rack/server'

require 'rack-rabbit/config'

module RackRabbit
  class Server

    attr_reader :app,
                :config

    def initialize(rackup, options)
      @config = Config.new(rackup, options)
    end

    def run
      load_app
      puts "Run #{app} (#{config.rackup})"
      puts " coming soon..."
    end

    def load_app
      @app, options = Rack::Builder.parse_file(config.rackup)
    end

  end
end
