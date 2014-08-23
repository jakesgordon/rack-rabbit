module RackRabbit
  class Response

    #--------------------------------------------------------------------------

    attr_reader :status, :headers, :body

    def initialize(status, headers, body)
      @status  = status
      @headers = headers
      @body    = body
    end

    #--------------------------------------------------------------------------

    def succeeded?
      (200..299).include?(status)
    end

    def failed?
      !succeeded?
    end

    #--------------------------------------------------------------------------

    def to_s
      if succeeded?
        body
      else
        case status
        when RackRabbit::STATUS::BAD_REQUEST then "#{status} Bad Request"
        when RackRabbit::STATUS::NOT_FOUND   then "#{status} Not Found"
        when RackRabbit::STATUS::FAILED      then "#{status} Internal Server Error"
        else
          status.to_s
        end
      end
    end

    #--------------------------------------------------------------------------

  end
end
