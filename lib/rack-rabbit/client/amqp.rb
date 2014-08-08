begin
  require 'amqp'
rescue LoadError
  abort "missing 'amqp' gem"
end

module RackRabbit
  module Client
    class AMQP

      attr_accessor :connection, :channel, :exchange

      def connected?
        !@connection.nil?
      end

      def connect
        return if connected?
        start_eventmachine
        @connection = ::AMQP.connect
        @channel = ::AMQP::Channel.new(connection)
        @exchange = channel.default_exchange
        channel.prefetch(1)
      end

      def disconnect
        channel.close unless channel.nil?
        connection.close unless connection.nil?
        stop_eventmachine
      end

      def subscribe(queue_name, &block)
        queue = channel.queue(queue_name)
        queue.subscribe do |properties, payload|
          yield Request.new(nil, properties, payload)
        end
      end

      def publish(payload, properties)
        exchange.publish(payload, properties)
      end

      def start_eventmachine
        raise RuntimeError, "already started" unless @thread.nil?
        ready = false
        @thread = Thread.new { EventMachine.run { ready = true } }
        sleep(1) until ready
      end

      def stop_eventmachine
        EventMachine.stop
      end

    end
  end
end
