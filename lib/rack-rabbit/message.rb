require 'stringio'

module RackRabbit
  class Message

    #--------------------------------------------------------------------------

    attr_reader :delivery_tag, :reply_to, :correlation_id,
                :body, :headers,
                :method, :uri, :path, :query, :status,
                :content_type, :content_encoding, :content_length,
                :rabbit

    def initialize(delivery_tag, properties, body, rabbit)
      @delivery_tag       = delivery_tag
      @reply_to           = properties.reply_to
      @correlation_id     = properties.correlation_id
      @body               = body
      @headers            = properties.headers || {}
      @method             = headers.delete(RackRabbit::HEADER::METHOD) || :GET
      @uri                = headers.delete(RackRabbit::HEADER::PATH)   || ""
      @status             = headers.delete(RackRabbit::HEADER::STATUS)
      @path, @query       = uri.split(/\?/)
      @content_type       = properties.content_type
      @content_encoding   = properties.content_encoding
      @content_length     = body.nil? ? 0 : body.length
      @rabbit             = rabbit
      @acknowledged       = nil
      @rejected           = nil
    end

    #--------------------------------------------------------------------------

    def get_rack_env(defaults = {})

      defaults.merge({
        'rabbit.message' => self,
        'rack.input'     => StringIO.new(body || ""),
        'REQUEST_METHOD' => method,
        'REQUEST_PATH'   => uri,
        'PATH_INFO'      => path,
        'QUERY_STRING'   => query,
        'CONTENT_TYPE'   => "#{content_type || 'text/plain'}; charset=\"#{content_encoding || 'utf-8'}\"",
        'CONTENT_LENGTH' => content_length
      }).merge(headers)
    
    end

    #--------------------------------------------------------------------------

    def should_reply?
      !reply_to.nil?
    end

    def get_reply_properties(response, config)
      return {
        :app_id           => config.app_id,
        :routing_key      => reply_to,
        :correlation_id   => correlation_id,
        :timestamp        => Time.now.to_i,
        :headers          => response.headers.merge(RackRabbit::HEADER::STATUS => response.status),
        :content_type     => response.headers[RackRabbit::HEADER::CONTENT_TYPE],
        :content_encoding => response.headers[RackRabbit::HEADER::CONTENT_ENCODING]
      }
    end

    #--------------------------------------------------------------------------

    def ack
      raise RuntimeError, "already acknowledged" if acknowledged?
      raise RuntimeError, "already rejected"     if rejected?
      @acknowledged = true
      rabbit.ack(delivery_tag)
    end

    def reject
      raise RuntimeError, "already acknowledged" if acknowledged?
      raise RuntimeError, "already rejected"     if rejected?
      @rejected = true
      rabbit.reject(delivery_tag)
    end

    def acknowledged?
      @acknowledged == true
    end

    def rejected?
      @rejected == true
    end

    #--------------------------------------------------------------------------

  end
end


  
