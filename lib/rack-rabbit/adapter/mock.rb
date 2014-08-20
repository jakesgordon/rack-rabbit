module RackRabbit
  class Adapter
    class Mock < RackRabbit::Adapter

      attr_accessor :connection, :channel, :exchange

      def connected?
        !@connection.nil?
      end

      def connect
        return if connected?
        @connection = OpenStruct.new
        @channel    = OpenStruct.new
        @exchange   = OpenStruct.new
      end

      def disconnect
      end

      def subscribe(queue, options = {}, &block)
        # TODO
      end

      def publish(payload, properties)
        # TODO
      end

      def with_reply_queue(&block)
        # TODO
      end

      def ack(delivery_tag)
        acked_messages << delivery_tag
      end

      def reject(delivery_tag, requeue = false)
        if requeue
          requeued_messages << delivery_tag
        else
          rejected_messages << delivery_tag 
        end
      end

      def acked_messages
        @acked_messages ||= []
      end

      def rejected_messages
        @rejected_messages ||= []
      end

      def requeued_messages
        @requeued_messages ||= []
      end

    end

  end
end

