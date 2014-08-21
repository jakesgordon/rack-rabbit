class MyApp

  def self.call(env)

    request = Rack::Request.new env
    logger  = request.logger
    path    = request.path_info

    if path && path.include?("sleep")
      duration = path.to_s.split("/").last.to_i
      duration.times do |n|
        logger.info "sleep #{n}"
        sleep(1)
      end
    end

    response = Rack::Response.new
    response.write "Method: #{request.request_method}\n"
    response.write "Path: #{path}\n"
    response.write "Query: #{request.query_string}\n" unless request.query_string.empty?
    response.write "Slept for: #{duration}\n" unless duration.nil?
    response.write request.body.read
    response.status = 200
    response.finish

  end

end
