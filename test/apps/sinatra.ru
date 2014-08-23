require 'sinatra/base'

class MyApp < Sinatra::Base

  set :logging, nil   # skip sinatra logging middleware, use the env['rack.logger'] provided by the rack-rabbit server

  get "/hello" do
    "Hello World"
  end

  get "/noop/:label" do
    "noop"
  end

  post "/submit" do
    "Submitted #{request.body.read}"
  end

  get "/error" do
    raise "uh oh"
  end

  get "/sleep/:seconds" do
    slumber params[:seconds].to_i
  end

  post "/sleep/:seconds" do
    slumber params[:seconds].to_i
  end

  def slumber(seconds)
    seconds.times do |i|
      logger.info "#{request.path_info} - #{i}"
      sleep(1)
    end
    "Slept for #{seconds}"
  end

end

run MyApp
