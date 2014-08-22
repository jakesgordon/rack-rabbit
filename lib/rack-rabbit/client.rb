require 'securerandom'

require 'rack-rabbit'
require 'rack-rabbit/adapter'
require 'rack-rabbit/message'
require 'rack-rabbit/response'

module RackRabbit
  class Client

    #--------------------------------------------------------------------------

    attr_reader :rabbit

    def initialize(options = {})
      @rabbit = Adapter.load(DEFAULT_RABBIT.merge(options))
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

    def get(path, options = {})
      request(options.merge(:method => :GET, :path => path))
    end

    def post(path, body, options = {})
      request(options.merge(:method => :POST, :path => path, :body => body))
    end

    def put(path, body, options = {})
      request(options.merge(:method => :PUT, :path => path, :body => body))
    end

    def delete(path, options = {})
      request(options.merge(:method => :DELETE, :path => path))
    end

    #--------------------------------------------------------------------------

    def request(options = {})

      id        = SecureRandom.uuid
      lock      = Mutex.new
      condition = ConditionVariable.new
      method    = options[:method]  || :GET
      path      = options[:path]    || ""
      headers   = options[:headers] || {}
      body      = options[:body]    || ""
      response  = nil

      rabbit.with_reply_queue do |reply_queue|

        rabbit.subscribe(reply_queue) do |message|
          if message.correlation_id == id
            response = Response.new(message.status, message.headers, message.body)
            lock.synchronize { condition.signal }
          end
        end

        rabbit.publish(body,
          :correlation_id   => id,
          :reply_to         => reply_queue.name,
          :priority         => options[:priority],
          :routing_key      => options[:routing_key],
          :content_type     => options[:content_type]     || default_content_type,
          :content_encoding => options[:content_encoding] || default_content_encoding,
          :timestamp        => options[:timestamp]        || default_timestamp,
          :headers          => headers.merge({
            RackRabbit::HEADER::METHOD => method.to_s.upcase,
            RackRabbit::HEADER::PATH   => path
          })
        )

      end

      lock.synchronize { condition.wait(lock) }

      response

    end

    #--------------------------------------------------------------------------

    def enqueue(options = {})

      method  = options[:method]  || :GET
      path    = options[:path]    || ""
      headers = options[:headers] || {}
      body    = options[:body]    || ""

      rabbit.publish(body,
        :priority         => options[:priority],
        :routing_key      => options[:routing_key],
        :content_type     => options[:content_type]     || default_content_type,
        :content_encoding => options[:content_encoding] || default_content_encoding,
        :timestamp        => options[:timestamp]        || default_timestamp,
        :headers          => headers.merge({
          RackRabbit::HEADER::METHOD => method.to_s.upcase,
          RackRabbit::HEADER::PATH   => path
        })
      )

      true

    end

    #--------------------------------------------------------------------------

    def default_content_type
      'text/plain; charset = "utf-8"'
    end

    def default_content_encoding
      'utf-8'
    end

    def default_timestamp
      Time.now.to_i
    end

    #--------------------------------------------------------------------------

    def self.define_class_method_for(method_name)
      define_singleton_method(method_name) do |*params|
        options  = params.last.is_a?(Hash) ? params.pop : {}
        client   = Client.new(options.delete(:rabbit))
        response = client.send(method_name, *params, options)
        client.disconnect
        response
      end
    end

    define_class_method_for :get
    define_class_method_for :post
    define_class_method_for :put
    define_class_method_for :delete
    define_class_method_for :request
    define_class_method_for :enqueue

    #--------------------------------------------------------------------------

  end
end
