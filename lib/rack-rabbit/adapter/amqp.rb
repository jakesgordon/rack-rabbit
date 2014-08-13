begin
  require 'amqp'
rescue LoadError
  abort "missing 'amqp' gem"
end

require 'rack-rabbit/request'

module RackRabbit
  module Adapter
    class AMQP

      attr_accessor :connection, :channel, :exchange

      def startup
        startup_eventmachine
      end

      def shutdown
        shutdown_eventmachine
      end

      def connected?
        !@connection.nil?
      end

      def connect
        return if connected?
        @connection = ::AMQP.connect
        @channel = ::AMQP::Channel.new(connection)
        @exchange = channel.default_exchange
        channel.prefetch(1)
      end

      def disconnect
        channel.close unless channel.nil?
        connection.close unless connection.nil?
      end

      def subscribe(queue, &block)
        queue = channel.queue(queue) if queue.is_a?(Symbol) || queue.is_a?(String)
        queue.subscribe do |properties, payload|
          yield Request.new(nil, properties, payload)
        end
      end

      def publish(payload, properties)
        exchange.publish(payload, properties)
      end

      def with_reply_queue
        channel.queue("", :exclusive => true, :auto_delete => true) do |reply_queue, declare_ok|
          yield reply_queue
        end
      end

    private

      def startup_eventmachine
        raise RuntimeError, "already started" unless @thread.nil?
        ready = false
        @thread = Thread.new { EventMachine.run { ready = true } }
        sleep(1) until ready
        sleep(1) # warmup
      end

      def shutdown_eventmachine
        sleep(1) # warmdown
        EventMachine.stop
      end

    end
  end
end
