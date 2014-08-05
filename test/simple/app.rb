class SimpleApp

  def self.call(env)

    method = env["REQUEST_METHOD"]
    path   = env["PATH_INFO"]
    query  = env["QUERY_STRING"]
    body   = env["rack.input"].read
    logger = env["rack.logger"]

    response = []
    response << "Method: #{method}"
    response << "Path: #{path}"
    response << "Query: #{query}" unless query.nil? || query.empty?
    response << body

    [ 200, {}, [ response.join("\n") ] ]

  end

end
