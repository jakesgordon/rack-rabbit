class ExamineApp
  def self.call(env)
    request = {
      :method => env['REQUEST_METHOD'],
      :path   => env['REQUEST_PATH'],
      :body   => env['rack.input'].read
    }
    [ 200, {}, [ request.to_json ] ]
  end
end

run ExamineApp

