module RackRabbit
  class Adapter
    class Mock < RackRabbit::Adapter

      attr_accessor :connection

      def startup
        @started = true
      end

      def shutdown
        @started = false
      end

      def started?
        !!@started
      end

      def connect
        @connected = true
      end

      def disconnect
        @connected = false
      end

      def connected?
        !!@connected
      end

      def subscribe(options = {}, &block)
        @subscribe_options = options
        while !queue.empty?
          message = queue.shift
          yield message
          subscribed_messages << message
        end
      end

      def publish(body, properties)
        published_messages << properties.merge(:body => body)
      end

      def with_reply_queue(&block)
        yield OpenStruct.new :name => "reply.queue"
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

      #========================================================================
      # TEST HELPER METHODS
      #========================================================================

      def acked_messages
        @acked_messages ||= []
      end

      def rejected_messages
        @rejected_messages ||= []
      end

      def requeued_messages
        @requeued_messages ||= []
      end

      def published_messages
        @published_messages ||= []
      end

      def subscribed_messages
        @subscribed_messages ||= []
      end

      def queue
        @queue ||= []
      end

      def prime(message)
        queue << message
      end

      def subscribe_options
        @subscribe_options
      end

    end

  end
end

