begin
  require 'bunny'
rescue LoadError
  abort "missing 'bunny' gem"
end

module RackRabbit
  class Adapter
    class Bunny < RackRabbit::Adapter

      attr_accessor :connection, :channel

      def connect
        return if connected?
        @connection = ::Bunny.new(connection_options)
        connection.start
        @channel = connection.create_channel
        channel.prefetch(1)
      end

      def disconnect
        channel.close unless channel.nil?
        connection.close unless connection.nil?
      end

      def connected?
        !@connection.nil?
      end

      def subscribe(options = {}, &block)
        queue    = get_queue(options.delete(:queue)) || channel.queue("", :exclusive => true)
        exchange = get_exchange(options.delete(:exchange), options.delete(:exchange_type))
        if exchange
          queue.bind(exchange, :routing_key => options.delete(:routing_key))
        end
        queue.subscribe(options) do |delivery_info, properties, payload|
          yield Message.new(delivery_info.delivery_tag, properties, payload, self)
        end
      end

      def publish(payload, properties)
        exchange = get_exchange(properties.delete(:exchange), properties.delete(:exchange_type))
        exchange ||= channel.default_exchange
        exchange.publish(payload || "", properties)
      end

      def with_reply_queue(&block)
        yield channel.queue("", :exclusive => true, :auto_delete => true)
      end

      def ack(delivery_tag)
        channel.acknowledge(delivery_tag, false)
      end

      def reject(delivery_tag)
        channel.reject(delivery_tag, false)
      end

      #========================================================================
      # PRIVATE IMPLEMENTATION
      #========================================================================

      private

      def get_exchange(ex = :default, type = :direct)
        case ex
        when ::Bunny::Exchange then ex
        when Symbol, String    then channel.send(type || :direct, ex) unless ex.to_s.downcase.to_sym == :default
        else
          nil
        end
      end

      def get_queue(q)
        case q
        when ::Bunny::Queue then q
        when Symbol, String then channel.queue(q)
        else
          nil
        end
      end

      #------------------------------------------------------------------------

    end # class Bunny
  end # module Adapter
end # module RackRabbit
