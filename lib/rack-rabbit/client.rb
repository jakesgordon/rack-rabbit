require 'rack-rabbit/helpers'

module RackRabbit
  class Client

    #--------------------------------------------------------------------------

    include Helpers

    attr_reader :options, :adapter

    def initialize(options = {})
      @options = options
      @adapter = load_adapter(options[:adapter] || :bunny)
      adapter.connect
    end

    #--------------------------------------------------------------------------

    def connect
      adapter.connect
    end

    def disconnect
      adapter.disconnect
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

      reply_queue = adapter.create_exclusive_reply_queue
      id          = "#{rand}#{rand}#{rand}"  # TODO: better message ID's
      lock        = Mutex.new
      condition   = ConditionVariable.new
      headers     = options[:headers] || {}
      response    = nil

      adapter.subscribe(reply_queue) do |message|
        if message.correlation_id == id
          response = message.body
          lock.synchronize { condition.signal }
        end
      end

      adapter.publish(body,
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
