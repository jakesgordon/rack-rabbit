class SimpleApp

  def self.call(env)

    request = Rack::Request.new env
    logger  = request.logger
    path    = request.path_info

    duration = path.to_s.split("/").last.to_i
    duration.times do |n|
      logger.info "sleeper #{n}"
      sleep 1
    end

    unless path.nil?
      env["rabbit.message"].ack    if path.include?("ackit")
      env["rabbit.message"].reject if path.include?("rejectit")
      raise "wtf"                  if path.include?("error")
    end

    response = Rack::Response.new
    response.write "Method: #{request.request_method}\n"
    response.write "Path: #{path}\n"
    response.write "Query: #{request.query_string}\n" unless request.query_string.empty?
    response.write "Duration: #{duration}\n"
    response.write request.body.read
    response.status = 200
    response.finish

  end

end
