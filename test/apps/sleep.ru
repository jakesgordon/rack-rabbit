class SleepApp

  def self.call(env)

    request = Rack::Request.new env
    logger  = request.logger
    path    = request.path_info.to_s

    duration = path.split("/").last.to_i
    duration.times do |n|
      logger.info "#{path} - #{n}"
      sleep(1)
    end

    [ 200, {}, [ "Slept for: #{duration}" ] ]

  end

end

run SleepApp
