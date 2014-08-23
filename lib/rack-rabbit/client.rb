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

    def get(queue, path, options = {})
      request(queue, options.merge(:method => :GET, :path => path))
    end

    def post(queue, path, body, options = {})
      request(queue, options.merge(:method => :POST, :path => path, :body => body))
    end

    def put(queue, path, body, options = {})
      request(queue, options.merge(:method => :PUT, :path => path, :body => body))
    end

    def delete(queue, path, options = {})
      request(queue, options.merge(:method => :DELETE, :path => path))
    end

    #--------------------------------------------------------------------------

    def request(queue, options = {})

      id        = options[:id] || SecureRandom.uuid    # allow dependency injection for test purposes
      lock      = Mutex.new
      condition = ConditionVariable.new
      method    = options[:method]  || :GET
      path      = options[:path]    || ""
      headers   = options[:headers] || {}
      body      = options[:body]    || ""
      response  = nil

      rabbit.with_reply_queue do |reply_queue|

        rabbit.subscribe(:queue => reply_queue) do |message|
          if message.correlation_id == id
            lock.synchronize do
              response = Response.new(message.status, message.headers, message.body)
              condition.signal
            end
          end
        end

        rabbit.publish(body,
          :correlation_id   => id,
          :routing_key      => queue,
          :reply_to         => reply_queue.name,
          :priority         => options[:priority],
          :content_type     => options[:content_type]     || default_content_type,
          :content_encoding => options[:content_encoding] || default_content_encoding,
          :timestamp        => options[:timestamp]        || default_timestamp,
          :headers          => headers.merge({
            RackRabbit::HEADER::METHOD => method.to_s.upcase,
            RackRabbit::HEADER::PATH   => path
          })
        )

      end

      lock.synchronize do
        condition.wait(lock) unless response
      end

      response

    end

    #--------------------------------------------------------------------------

    def enqueue(queue, options = {})

      method  = options[:method]  || :POST
      path    = options[:path]    || ""
      headers = options[:headers] || {}
      body    = options[:body]    || ""

      rabbit.publish(body,
        :routing_key      => queue,
        :priority         => options[:priority],
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

    def publish(exchange, options = {})

      method  = options[:method]  || :POST
      path    = options[:path]    || ""
      headers = options[:headers] || {}
      body    = options[:body]    || ""

      rabbit.publish(body,
        :exchange         => exchange,
        :exchange_type    => options[:exchange_type] || :fanout,
        :routing_key      => options[:routing_key],
        :priority         => options[:priority],
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
      'text/plain'
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
    define_class_method_for :publish

    #--------------------------------------------------------------------------

  end
end
