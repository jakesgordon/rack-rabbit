module RackRabbit
  class Response

    #--------------------------------------------------------------------------

    attr_reader :status, :headers, :body

    def initialize(status, headers, body)
      @status  = status
      @headers = headers
      @body    = body
    end

    def content_type
      headers[RackRabbit::HEADER::CONTENT_TYPE]
    end

    def content_encoding
      headers[RackRabbit::HEADER::CONTENT_ENCODING]
    end

    def succeeded?
      status == 200     # TODO: broaden this definition
    end

    def failed?
      !succeeded?
    end

    #--------------------------------------------------------------------------

    def to_s
      case status
      when RackRabbit::STATUS::SUCCESS   then body
      when RackRabbit::STATUS::NOT_FOUND then "#{status} Not Found"
      when RackRabbit::STATUS::FAILED    then "#{status} Internal Server Error"
      else
        status.to_s
      end
    end

    #--------------------------------------------------------------------------

  end
end
