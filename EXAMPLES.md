# Examples

## Contents

 - [Synchronous Request/Response (using Rack)](#synchronous-requestresponse-using-rack)
 - [Synchronous Request/Response (using Sinatra)](#synchronous-requestresponse-using-sinatra)
 - [Asynchronous Worker Queue](#asynchronous-worker-queue)
 - [Asynchronous Publish/Subscribe with a fanout exchange](#asynchronous-publishsubscribe-with-a-fanout-exchange)
 - [Asynchronous Publish/Subscribe with a topic exchange](#asynchronous-publishsubscribe-with-a-topic-exchange)

## Synchronous Request/Response (using Rack)

Consider this simple rack application in `config.ru`:

    class Service
      def self.call(env)
        request = Rack::Request.new(env)
        method  = request.request_method
        path    = request.path_info
        body    = request.body.read
        message = "#{method} #{path} #{body}"
        [ 200, {}, [ message ]]
      end
    end
    run Service

Host and load balance this service using `rack-rabbit`:

    $ rack-rabbit --queue myqueue --workers 4  config.ru

Connect to the worker from the command line using the `rr` command:

    $ rr -q myqueue /hello                    # synchronous GET request/response
    GET /hello

    $ rr -q myqueue POST /submit "data"       # synchronous POST request/response
    POST /submit data

    $ rr -q myqueue PUT /update "data"        # synchronous PUT request/response
    PUT /update data

    $ rr -q myqueue DELETE /resource          # synchronous DELETE request/response
    DELETE /resource


Connect to the worker from your application using the `RR` class.

    require 'rack-rabbit/client'

    RR.get    :myqueue, "/hello"             # returns "GET /hello"
    RR.post   :myqueue, "/submit", "data"    # returns "POST /submit data"
    RR.put    :myqueue, "/update", "data"    # returns "PUT /update data"
    RR.delete :myqueue, "/resource",         # returns "DELETE /resource"


## Synchronous Request/Response (using Sinatra)

Consider this simple sinatra application in `config.ru`:

    require 'sinatra/base'

    class Service < Sinatra::Base

      get "/hello" do
        "Hello World"
      end

      post "/submit" do
        "Submitted #{request.body.read}"
      end

    end

    run Service

Host and load balance this service using `rack-rabbit`:

    $ rack-rabbit --queue myqueue --workers 4 config.ru

Connect to the worker from the command line using the `rr` command:

    $ rr request -q myqueue GET /hello
    Hello World

    $ rr request -q myqueue POST /submit "data"
    Submitted data

Connect to the worker from your application using the `RR` class:

    require 'rack-rabbit/client'

    RR.get  :myqueue, "/hello"            # returns "Hello World"
    RR.post :myqueue, "/submit", "data"   # returns "Submitted data"


## Asynchronous Worker Queue

Consider this simple sinatra application in `config.ru`:

    require 'sinatra/base'

    class Service < Sinatra::Base

      post "/work do
        logger.info "do some work using #{request.body.read}"
      end

      post "/more/work" do
        logger.info "do some more work using #{request.body.read}"
      end

    end

    run Service

Host and load balance this service using `rack-rabbit`:

    $ rack-rabbit --queue myqueue --workers 4 config.ru

Enqueue some work from the command line using the `rr` command:

    $ rr enqueue -q myqueue /work      "data"          # asynchronous ENQUEUE to a worker
    $ rr enqueue -q myqueue /more/work "more data"     # (ditto)

Enqueue some work from your application using the `RR` class:

    require 'rack-rabbit/client'

    RR.enqueue :myqueue, :path => "/work",     :body => "data"
    RR.enqueue :myqueue, :path => "/more/work" :body => "more data"

## Asynchronous Publish/Subscribe with a fanout exchange

Consider two potential subscribers:

First `foo.ru`

    require 'sinatra/base'

    class Foo < Sinatra::Base
      post "/event do
        logger.info "Foo saw the event"
      end
    end
    run Foo

Then `bar.ru`

    require 'sinatra/base'

    class Bar < Sinatra::Base
      post "/event do
        logger.info "Bar saw the event"
      end
    end
    run Bar

Host these subscribers using `rack-rabbit`:

    $ rack-rabbit --exchange myexchange --type fanout foo.ru  &
    $ rack-rabbit --exchange myexchange --type fanout bar.ru  &

Publish the event from the command line using the `rr` command:

    $ rr publish -e myexchange -t fanout "/event" "data"

Publish the event from your application using the `RR` class:

    require 'rack-rabbit/client'

    RR.publish :myexchange, :type => :fanout, :path => "/event", :body => "data"

>> **All subscribers should see the event when using a fanout exchange**


## Asynchronous Publish/Subscribe with a topic exchange

Consider the same two subscribers as in the previous example, but host them by binding to a routed topic exchange:

    $ rack-rabbit --exchange myexchange --type topic --route A foo.ru &
    $ rack-rabbit --exchange myexchange --type topic --route B bar.ru &

Publish a routed event from the command line using the `rr` command:

    $ rr publish -e myexchange -t topic -r A "/event"          # only received by foo
    $ rr publish -e myexchange -t topic -r B "/event"          # only received by bar

Publish a routed event from your application using the `RR` class:

    require 'rack-rabbit/client'

    RR.publish :myexchange, :type => :topic, :route => "A", :path => "/event"   # only received by foo
    RR.publish :myexchange, :type => :topic, :route => "B", :path => "/event"   # only received by bar

>> **Subscribers should only see events that match their route when using a topic exchange**

