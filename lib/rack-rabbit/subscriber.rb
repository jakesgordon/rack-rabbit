require 'rack-rabbit/adapter'
require 'rack-rabbit/handler'

module RackRabbit
  class Subscriber

    #--------------------------------------------------------------------------

    attr_reader :config,  # configuration options provided by the Server
                :logger,  # convenience for config.logger
                :rabbit,  # rabbitMQ adapter constructed by this class
                :handler, # actually does the work of handling the RACK request/response
                :lock     # mutex to synchronize with Worker#shutdown for graceful QUIT handling

    #--------------------------------------------------------------------------

    def initialize(rabbit, handler, lock, config)
      @rabbit  = rabbit
      @handler = handler
      @lock    = lock
      @config  = config
      @logger  = config.logger
    end

    #--------------------------------------------------------------------------

    def subscribe
      rabbit.startup
      rabbit.connect
      rabbit.subscribe(:queue         => config.queue,
                       :exchange      => config.exchange,
                       :exchange_type => config.exchange_type,
                       :routing_key   => config.routing_key,
                       :ack           => config.ack) do |message|
        lock.synchronize do
          start = Time.now
          response = handle(message)
          finish = Time.now
          logger.info "\"#{message.method} #{message.path}\" [#{response.status}] - #{"%.4f" % (finish - start)}"
        end
      end
    end

    def unsubscribe
      rabbit.disconnect
      rabbit.shutdown
    end

    #==========================================================================
    # PRIVATE IMPLEMENTATION
    #==========================================================================

    private

    def handle(message)

      response = handler.handle(message) # does all the Rack related work

      if message.should_reply?
        rabbit.publish(response.body, message.get_reply_properties(response, config))
      end

      if config.ack && !message.acknowledged? && !message.rejected?
        if response.succeeded?
          message.ack
        else
          message.reject
        end
      end

      response
    end

    #--------------------------------------------------------------------------

  end # class Subscriber
end # module RackRabbit
