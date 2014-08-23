require 'json'

class MirrorApp
  def self.call(env)

    request = Rack::Request.new env
    result  = {
      :method => request.request_method,
      :path   => request.path_info,
      :params => request.params,
      :body   => request.body.read
    }

    [ 200, {}, [ result.to_json ] ]

  end
end

run MirrorApp
