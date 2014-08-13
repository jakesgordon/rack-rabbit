require 'rack-rabbit/adapter'

module RackRabbit
  class Client

    #--------------------------------------------------------------------------

    attr_reader :options, :rabbit

    def initialize(options = {})
      @options = options
      @rabbit  = Adapter.load(options[:adapter] || :bunny)
      connect
    end

    #--------------------------------------------------------------------------

    def connect
      rabbit.connect
    end

    def disconnect
      rabbit.disconnect
    end

    #--------------------------------------------------------------------------

    def get(queue, path, options = {})
      request(queue, "GET", path, "", options)
    end

    def post(queue, path, body, options = {})
      request(queue, "POST", path, body, options)
    end

    #--------------------------------------------------------------------------

    def request(queue, method, path, body, options = {})

      id        = "#{rand}#{rand}#{rand}"  # TODO: better message ID's
      lock      = Mutex.new
      condition = ConditionVariable.new
      headers   = options[:headers] || {}
      response  = nil

      rabbit.with_reply_queue do |reply_queue|

        rabbit.subscribe(reply_queue) do |message|
          if message.correlation_id == id
            response = message.body
            lock.synchronize { condition.signal }
          end
          :wtf
        end

        rabbit.publish(body,
          :message_id       => id,
          :app_id           => options[:app_id] || default_app_id,
          :priority         => options[:priority],
          :routing_key      => queue,
          :reply_to         => reply_queue.name,
          :type             => method.to_s.upcase,
          :content_type     => options[:content_type]     || default_content_type,
          :content_encoding => options[:content_encoding] || default_content_encoding,
          :timestamp        => options[:timestamp]        || default_timestamp,
          :headers          => headers.merge({
            :path => path
          })
        )

      end

      lock.synchronize { condition.wait(lock) }

      response     # TODO: error handling

    end

    #--------------------------------------------------------------------------

    def default_app_id
      options[:app_id] ||= 'rack-rabbit-client'
    end

    def default_content_type
      options[:content_type] ||= 'text/plain; charset = "utf-8"'
    end

    def default_content_encoding
      options[:content_encoding] ||= 'utf-8'
    end

    def default_timestamp
      Time.now.to_i
    end

    #--------------------------------------------------------------------------

  end
end
