module RackRabbit
  class Request

    #--------------------------------------------------------------------------

    attr_reader :reply_to, :correlation_id,
                :body, :headers,
                :method, :uri, :path, :query,
                :content_type, :content_encoding, :content_length

    def initialize(info, properties, body)
      @reply_to           = properties.reply_to
      @correlation_id     = properties.correlation_id
      @body               = body
      @headers            = properties.headers || {}
      @method             = properties.type || headers['method'] || "GET"
      @uri                = headers['path'] || ""
      @path, @query       = uri.split(/\?/)
      @content_type       = properties.content_type
      @content_encoding   = properties.content_encoding if properties.respond_to?(:content_encoding)
      @content_length     = body.length
    end

    def should_reply?
      !reply_to.nil?
    end

    #--------------------------------------------------------------------------

  end
end


  
