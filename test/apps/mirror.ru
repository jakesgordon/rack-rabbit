class MirrorApp
  def self.call(env)

    request = Rack::Request.new env
    method  = request.request_method
    path    = request.path_info
    body    = request.body.read

    [ 200, {}, [ "#{method} #{path} #{body}" ] ]

  end
end

run MirrorApp
