class ErrorApp
  def self.call(env)

    raise env["exception"] if env.key?("exception")  # let caller trigger exception if desired

    status  = env["status"]  || 500                         # let caller specify error status code
    message = env["message"] || "Internal Server Error"     # let caller specify error message

    [ status, {}, [ message ] ]

  end
end

run ErrorApp
