begin
  require 'bunny'
rescue LoadError
  abort "missing 'bunny' gem"
end

module RackRabbit
  module Client
    class Bunny

      attr_accessor :connection, :channel, :exchange

      def connected?
        !@connection.nil?
      end

      def connect
        return if connected?
        @connection = ::Bunny.new
        connection.start
        @channel = connection.create_channel
        @exchange = channel.default_exchange
        channel.prefetch(1)
      end

      def disconnect
        channel.close unless channel.nil?
        connection.close unless connection.nil?
      end

      def subscribe(queue_name, &block)
        queue = channel.queue(queue_name)
        queue.subscribe do |delivery_info, properties, payload|
          yield Request.new(delivery_info, properties, payload)
        end
      end

      def publish(payload, properties)
        exchange.publish(payload, properties)
      end

    end

  end
end
