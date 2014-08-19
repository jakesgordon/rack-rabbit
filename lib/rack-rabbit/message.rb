module RackRabbit
  class Message

    #--------------------------------------------------------------------------

    attr_reader :rabbit, :delivery_tag, :reply_to, :correlation_id,
                :body, :headers,
                :method, :uri, :path, :query, :status,
                :content_type, :content_encoding, :content_length

    def initialize(rabbit, delivery_tag, properties, body)
      @rabbit             = rabbit
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
      @content_length     = body.length
    end

    def should_reply?
      !reply_to.nil?
    end

    #--------------------------------------------------------------------------

    def ack
      confirm(:ack) do
        rabbit.ack(delivery_tag)
      end
    end

    def reject(requeue = false)
      confirm(:reject) do
        rabbit.reject(delivery_tag, requeue)
      end
    end

    def acknowledged?
      @confirmed == :ack
    end

    def rejected?
      @confirmed == :reject
    end

    def confirmed?
      !!@confirmed
    end

    #--------------------------------------------------------------------------

    private

    def confirm(how)
      raise RuntimeError, "already acknowledged" if acknowledged?
      raise RuntimeError, "already rejected"     if rejected?
      yield
      @confirmed = how
    end

    #--------------------------------------------------------------------------

  end
end


  
