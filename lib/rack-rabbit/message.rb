module RackRabbit
  class Message

    #--------------------------------------------------------------------------

    attr_reader :reply_to, :correlation_id,
                :body, :headers,
                :method, :uri, :path, :query, :status,
                :content_type, :content_encoding, :content_length

    def initialize(properties, body)
      @reply_to           = properties.reply_to
      @correlation_id     = properties.correlation_id
      @body               = body
      @headers            = properties.headers || {}
      @method             = headers.delete(RackRabbit::HEADER::METHOD) || "GET"
      @uri                = headers.delete(RackRabbit::HEADER::PATH)   || ""
      @status             = headers.delete(RackRabbit::HEADER::STATUS)
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


  
