require 'stringio'

module RackRabbit
  class Message

    #--------------------------------------------------------------------------

    attr_reader :delivery_tag, :reply_to, :correlation_id,
                :body, :headers,
                :method, :uri, :path, :query, :status,
                :content_type, :content_encoding, :content_length

    def initialize(delivery_tag, properties, body)
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
      @content_encoding   = properties.content_encoding if properties.respond_to?(:content_encoding)
      @content_length     = body.nil? ? 0 : body.length
    end

    #--------------------------------------------------------------------------

    def to_rack_env(defaults = {})

      defaults.merge({
        'rabbit.message' => self,
        'rack.input'     => StringIO.new(body || ""),
        'REQUEST_METHOD' => method,
        'REQUEST_PATH'   => uri,
        'PATH_INFO'      => path,
        'QUERY_STRING'   => query,
        'CONTENT_TYPE'   => content_type,
        'CONTENT_LENGTH' => content_length
      }).merge(headers)
    
    end

    #--------------------------------------------------------------------------

    def should_reply?
      !reply_to.nil?
    end

    #--------------------------------------------------------------------------

    def confirm(succeeded)
      raise RuntimeError, "already acknowledged" if acknowledged?
      raise RuntimeError, "already rejected"     if rejected?
      @confirmed = succeeded
    end

    def acknowledged?
      @confirmed == true
    end

    def rejected?
      @confirmed == false
    end

    def confirmed?
      !@confirmed.nil?
    end

    #--------------------------------------------------------------------------

  end
end


  
