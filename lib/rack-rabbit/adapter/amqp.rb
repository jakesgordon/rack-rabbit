begin
  require 'amqp'
rescue LoadError
  abort "missing 'amqp' gem"
end

module RackRabbit
  class Adapter
    class AMQP < RackRabbit::Adapter

      attr_accessor :connection, :channel

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
        @connection = ::AMQP.connect(connection_options)
        @channel = ::AMQP::Channel.new(connection)
        channel.prefetch(1)
      end

      def disconnect
        channel.close unless channel.nil?
        connection.close unless connection.nil?
      end

      def subscribe(options = {}, &block)
        queue = get_queue(options.delete(:queue)) || channel.queue("", :exclusive => true)
        exchange = get_exchange(options.delete(:exchange), options.delete(:exchange_type))
        if exchange
          queue.bind(exchange, :routing_key => options.delete(:routing_key))
        end
        queue.subscribe(options) do |properties, payload|
          yield Message.new(properties.delivery_tag, properties, payload)
        end
      end

      def publish(payload, properties)
        exchange = get_exchange(properties.delete(:exchange), properties.delete(:exchange_type))
        exchange ||= channel.default_exchange
        exchange.publish(payload || "", properties)
      end

      def with_reply_queue
        channel.queue("", :exclusive => true, :auto_delete => true) do |reply_queue, declare_ok|
          yield reply_queue
        end
      end

      def ack(delivery_tag)
        channel.acknowledge(delivery_tag, false)
      end

      def reject(delivery_tag, requeue = false)
        channel.reject(delivery_tag, requeue)
      end

      #========================================================================
      # PRIVATE IMPLEMENTATION
      #========================================================================

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

      def get_exchange(ex = :default, type = :direct)
        case ex
        when ::AMQP::Exchange then ex
        when Symbol, String    then channel.send(type || :direct, ex) unless ex.to_s.downcase.to_sym == :default
        else
          nil
        end
      end

      def get_queue(q)
        case q
        when ::AMQP::Queue then q
        when Symbol, String then channel.queue(q)
        else
          nil
        end
      end

      #------------------------------------------------------------------------

    end
  end
end
