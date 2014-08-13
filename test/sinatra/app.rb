require 'sinatra/base'

class MyApp < Sinatra::Base

  get "/hello" do
    "Hello World"
  end

  post "/submit" do
    "Submitted #{request.body.read}"
  end

end
