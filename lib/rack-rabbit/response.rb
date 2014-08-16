module RackRabbit
  class Response

    #--------------------------------------------------------------------------

    attr_reader :status,
                :headers,
                :body,
                :content_type,
                :content_encoding

    def initialize(status, headers, body)
      @status           = status
      @headers          = headers
      @body             = body
      @content_type     = headers.delete('Content-Type')
      @content_encoding = headers.delete('Content-Encoding')
      headers[:status]  = status # also include status in headers passed back to the client
    end

    #--------------------------------------------------------------------------

  end
end
