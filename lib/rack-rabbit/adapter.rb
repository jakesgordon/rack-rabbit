require 'rack-rabbit/message'

module RackRabbit
  class Adapter

    #--------------------------------------------------------------------------

    def self.load(options)
      adapter = options.delete(:adapter) || :bunny
      if adapter.is_a?(Symbol) || adapter.is_a?(String)
        adapter = case adapter.to_s.downcase.to_sym
                  when :bunny
                    require 'rack-rabbit/adapter/bunny'
                    RackRabbit::Adapter::Bunny
                  when :amqp
                    require 'rack-rabbit/adapter/amqp'
                    RackRabbit::Adapter::AMQP
                  when :mock
                    require 'rack-rabbit/adapter/mock'
                    RackRabbit::Adapter::Mock
                  else
                    raise ArgumentError, "unknown rabbitMQ adapter #{adapter}"
                  end
      end
      adapter.new(options)
    end

    #--------------------------------------------------------------------------

    attr_reader :connection_options

    def initialize(options)
      @connection_options = options
    end

    def startup
      # derived classes optionally override this (e.g. to startup EventMachine)
    end

    def shutdown
      # derived classes optionally override this (e.g. to shutdown EventMachine)
    end

    def connected?
      raise NotImplementedError, "derived classes must implement this"
    end

    def connect
      raise NotImplementedError, "derived classes must implement this"
    end

    def disconnect
      raise NotImplementedError, "derived classes must implement this"
    end

    def subscribe(queue, options = {}, &block)
      raise NotImplementedError, "derived classes must implement this"
    end

    def publish(payload, properties)
      raise NotImplementedError, "derived classes must implement this"
    end

    def with_reply_queue(&block)
      raise NotImplementedError, "derived classes must implement this"
    end

    def ack(delivery_tag)
      raise NotImplementedError, "derived classes must implement this"
    end

    def reject(delivery_tag, requeue = false)
      raise NotImplementedError, "derived classes must implement this"
    end

    #--------------------------------------------------------------------------

  end
end
