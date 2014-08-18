begin
  require 'bunny'
rescue LoadError
  abort "missing 'bunny' gem"
end

module RackRabbit
  class Adapter
    class Bunny < RackRabbit::Adapter

      attr_accessor :connection, :channel, :exchange

      def connected?
        !@connection.nil?
      end

      def connect
        return if connected?
        @connection = ::Bunny.new(connection_options)
        connection.start
        @channel = connection.create_channel
        @exchange = channel.default_exchange
        channel.prefetch(1)
      end

      def disconnect
        channel.close unless channel.nil?
        connection.close unless connection.nil?
      end

      def subscribe(queue, options = {}, &block)
        queue = channel.queue(queue) if queue.is_a?(Symbol) || queue.is_a?(String)
        queue.subscribe(options) do |delivery_info, properties, payload|
          yield Message.new(self, delivery_info.delivery_tag, properties, payload)
        end
      end

      def publish(payload, properties)
        exchange.publish(payload || "", properties)
      end

      def with_reply_queue(&block)
        yield channel.queue("", :exclusive => true, :auto_delete => true)
      end

      def ack(delivery_tag)
        channel.acknowledge(delivery_tag, false)
      end

      def reject(delivery_tag, requeue = false)
        channel.reject(delivery_tag, requeue)
      end

    end

  end
end
