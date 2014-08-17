require 'sinatra/base'

class MyApp < Sinatra::Base

  set :logging, nil   # skip sinatra logging middleware, use the env['rack.logger'] provided by the rack-rabbit server

  get "/hello" do
    "Hello World"
  end

  post "/submit" do
    "Submitted #{request.body.read}"
  end

  get "/error" do
    raise "uh oh"
  end

  get "/sleep/:seconds" do
    seconds = params[:seconds].to_i
    seconds.times do |i|
      logger.info "sleeping #{i}"
      sleep(1)
    end
    "Slept for #{seconds}"
  end

end
