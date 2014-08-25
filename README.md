# Rack Rabbit (v0.5.0)

A forking server for hosting rabbitMQ consumer processes as load balanced rack applications.

    $ rack-rabbit --queue myqueue --workers 4 app/config.ru

## Contents

  - [Summary](#summary)
  - [Installation](#installation)
  - [Getting started by example](#getting-started-by-example)
  - [More examples](https://github.com/jakesgordon/rack-rabbit/blob/master/EXAMPLES.md)
  - [Server usage](#server-usage)
  - [Server configuration](#server-configuration)
  - [Signals](#signals)
  - [Forking worker processes](#forking-worker-processes)
  - [RabbitMQ acknowledgements](#rabbitmq-acknowledgements)
  - [Client binary](#client-binary)
  - [Client library](#client-library)
  - [Supported platforms](#supported-platforms)
  - [TODO](#todo)
  - [License](#license)
  - [Credits](#credits)
  - [Contact](#contact)

## Summary

What Unicorn does for HTTP services, RackRabbit can do for hosting AMQP services, and more:

|                                      | HTTP            | AMQP                  |
|--------------------------------------|-----------------|-----------------------|
| Make a synchronous request/response  | Unicorn         | rabbitMQ + RackRabbit |
| Asynchronous worker queue            | Redis + Resque  | rabbitMQ + RackRabbit |
| Asynchronous publish/subscribe       | Redis           | rabbitMQ + RackRabbit |

RackRabbit hosts a cluster of worker processes that:
  * Subscribe to a queue/exchange
  * Convert incoming messages into a suitable Rack environment
  * Call your Rack app to handle the message
  * Publish a reply back to the original caller (if `reply_to` was provided)

RackRabbit supports a variety of messaging patterns:

  * Synchronous Request/Response _(e.g. GET/POST/PUT/DELETE)_
  * Asynchronous Worker queue    _(e.g. ENQUEUE)_
  * Asynchronous PubSub          _(e.g. PUBLISH)_

## Installation

Install a rabbitMQ server if necessary ([docs](https://www.rabbitmq.com/download.html)):

    $ sudo apt-get install rabbitmq-server

Update your Gemfile to include RackRabbit and your preferred rabbitMQ client library

    gem bunny,       "~> 1.4"             # or an alternative such as AMQP or march-hare
    gem rack-rabbit, "~> 0.1"


## Getting started by example

You can use RackRabbit to host an AMQP service as a rack application in the same way
that you might use Unicorn to host an HTTP service.

Imagine a simple rack application in `config.ru`:

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
    
You can host and load balance this service using `rack-rabbit`:

    $ rack-rabbit --queue myqueue --workers 4  config.ru

Ensure the worker processes are running:

    $ ps xawf | grep rack-rabbit
    15714 pts/4    Sl+    0:00  |   \_ ruby rack-rabbit --queue myqueue --workers 4  config.ru
    15716 pts/4    Sl+    0:00  |       \_ rack-rabbit -- waiting for request
    15718 pts/4    Sl+    0:00  |       \_ rack-rabbit -- waiting for request
    15721 pts/4    Sl+    0:00  |       \_ rack-rabbit -- waiting for request
    15723 pts/4    Sl+    0:00  |       \_ rack-rabbit -- waiting for request

Connect to the worker from the command line using the `rr` command:

    $ rr -q myqueue /hello                    # synchronous GET request/response
    GET /hello

    $ rr -q myqueue POST /submit "data"       # synchronous POST request/response
    POST /submit data

    $ rr -q myqueue PUT /update "data"        # synchronous PUT request/response
    PUT /update data

    $ rr -q myqueue DELETE /resource          # synchronous DELETE request/response
    DELETE /resource

Connect to the worker from your applications using the `RR` class.

    require 'rack-rabbit/client'

    RR.get    :myqueue, "/hello"             # returns "GET /hello"
    RR.post   :myqueue, "/submit", "data"    # returns "POST /submit data"
    RR.put    :myqueue, "/update", "data"    # returns "PUT /update data"
    RR.delete :myqueue, "/resource",         # returns "DELETE /resource"


See [EXAMPLES.md](https://github.com/jakesgordon/rack-rabbit/blob/master/EXAMPLES.md) for
more detailed examples, including ENQUEUE and PUBLISH communication patterns, and using Sinatra.


## Server usage

Use the `rack-rabbit` executable to host your Rack app in a forking server that
subscribes to either a named queue or an exchange.

    $ rack-rabbit --help

    A load balanced rack server for hosting rabbitMQ consumer processes.

    Usage:   rack-rabbit [options] rack-file

    Examples:

      rack-rabbit -h broker -q my.queue                          # subscribe to a named queue
      rack-rabbit -h broker -e my.exchange -t fanout             # subscribe to a fanout exchange
      rack-rabbit -h broker -e my.exchange -t topic -r my.topic  # subscribe to a topic exchange with a routing key
      rack-rabbit -c rack-rabbit.conf                            # subscribe with advanced options provided by a config file

    RackRabbit options:
        -c, --config CONFIG              provide options using a rack-rabbit configuration file
        -q, --queue QUEUE                subscribe to a queue for incoming requests
        -e, --exchange EXCHANGE          subscribe to an exchange for incoming requests
        -t, --type TYPE                  subscribe to an exchange for incoming requests - type (e.g. :direct, :fanout, :topic)
        -r, --route ROUTE                subscribe to an exchange for incoming requests - routing key
        -a, --app_id ID                  an app_id for this application server
            --host HOST                  the rabbitMQ broker IP address (default: 127.0.0.1)
            --port PORT                  the rabbitMQ broker port (default: 5672)

    Process options:
        -w, --workers COUNT              the number of worker processes (default: 1)
        -d, --daemonize                  run daemonized in the background (default: false)
        -p, --pid PIDFILE                the pid filename (default when daemonized: /var/run/<app_id>.pid)
        -l, --log LOGFILE                the log filename (default when daemonized: /var/log/<app_id>.log)
            --log-level LEVEL            the log level for rack rabbit output (default: info)
            --preload                    preload the rack app before forking worker processes (default: false)

    Ruby options:
        -I, --include PATH               an additional $LOAD_PATH (may be used more than once)
            --debug                      set $DEBUG to true
            --warn                       enable warnings

    Common options:
        -h, --help
        -v, --version



## Server configuration

Detailed configuration can be provided by an external config file using the `--config` option

    # set the Rack application to be used to handle messages (default 'config.ru'):
    rack_file 'app/config.ru'

    # set the rabbitMQ connection:
    rabbit :host    => '10.0.0.42',  # default '127.0.0.1'
           :port    => '1234'        # default '5672'
           :adapter => :amqp         # default :bunny

    # subscribe to a queue:
    queue 'my.queue'

    # ... or, subscribe to an exchange:
    exchange      'my.exchange'
    exchange_type :topic
    routing_key   'my.topic'

    # set the app_id used to identify your application in response messages
    app_id 'my-application'

    # enable rabbitMQ acknowledgements (default: false):
    ack true

    # set the initial number of worker processes (default: 1):
    workers 8

    # set the minimum number of worker processes (default: 1):
    min_workers 1

    # set the maximum number of worker processes (default: 100):
    max_workers 16

    # preload the Rack app in the server for faster worker forking (default: false):
    preload_app true

    # daemonize the process (default: false)
    daemonize true

    # set the path to the logfile
    logfile "/var/log/my-application.log"

    # set the path to the pidfile
    pidfile "/var/run/my-application.pid"

    # set the log level for the Rack Rabbit logger (default: info)
    log_level 'debug'

    # set the Logger to used by the Rack Rabbit server and the worker Rack applications (default: Logger)
    logger MyLogger.new

## Signals

Signals should be sent to the master process

  * HUP - reload the RackRabbit config file and gracefully restart all workers
  * QUIT - graceful shutdown, waits for workers to complete handling of their current message before finishing
  * TERM - quick shutdown kills all workers immediately
  * INT  - quick shutdown kills all workers immediately
  * TTIN - increase the number of worker processes by one
  * TTOU - decrease the number of worker processes by one

## Forking worker processes

If you are using the `preload_app` directive, your app will be loaded into the master
server process before any workers have forked. Therefore, you may need to re-initialize
resources after each worker process forks, e.g if using ActiveRecord:

    before_fork do |server|
      # no need for connection in the server process
      defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!
    end

    after_fork do |server, worker|
      # reestablish connection in each worker process
      defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
    end

This should NOT be needed when the `preload_app` directive is false.

>> _this is an issue with any preforking style server (e.g. Unicorn)_

## RabbitMQ acknowledgements

By default, an AMQP broker removes a message from the queue immediately after sending it to
the consumer. If the consumer dies before processing the message completely then the message
is lost. Users who need more control can configure the broker to use explicit
acknowledgements ([learn more](http://rubybunny.info/articles/queues.html#message_acknowledgements))
by setting the RackRabbit `ack` configuration option to `true`.

With explicit acknowledgements enabled...

 - If your rack handler succeeds (returns a 2xx status code) then RackRabbit will automatically send
   an acknowledgement to rabbitMQ.

 - If your rack handler fails (throws an exception or returns a non-2xx status code) then RackRabbit
   will automatically send a rejection to rabbitMQ - you might want to setup a dead-letter queue for
   these rejections.

 - If your rack handler process crashes then rabbitMQ will hand the message off to the next available
   worker process.

If your service action is idempotent then nothing more is needed.

However, if you need more fine-grained controls, then RackRabbit exposes the underlying message to your
application in the rack environment as `env['rabbit.message']`. You can use this object to explicitly
acknowledge or reject the message at any time during your rack handler, e.g:

      post "/work" do

          message = request.env['rabbit.message']

          # ... do some preliminary work (idempotent)

          if everything_looks_good

            message.ack     # take responsibility
            ...             # and do some more work (that might not be idempotent)

          else

            message.reject  # reject the message
            ...             # and (maybe) do some more work

          end

      end

## Client binary

Communicating with a RackRabbit hosted service from the command line can be done using the `rr` binary:

    Make a request to a RackRabbit service.

    Usage: rr <command> [options] [METHOD] [PATH] [BODY]

    list of commands:

     request      make  a synchronous  request to a rabbitMQ queue and wait for a reply
     enqueue      make an asynchronous request to a rabbitMQ queue and continue
     publish      make an asynchronous request to a rabbitMQ exchange with a routing key
     help         show help for a given topic or a help overview
     version      show version

    Examples:

     rr request -q queue              GET    /hello          # submit GET to queue and WAIT for reply
     rr request -q queue              POST   /submit 'data'  # submit POST to queue and WAIT for reply
     rr enqueue -q queue              POST   /submit 'data'  # submit POST to queue and CONTINUE
     rr enqueue -q queue              DELETE /resource       # submit DELETE to queue and CONTINUE
     rr publish -e ex -t fanout       POST   /event          # submit POST to a fanout exchange and CONTINUE
     rr publish -e ex -t topic -r foo POST   /submit 'data'  # submit POST to a topic exchange with routing key and CONTINUE

    RackRabbit options:
            --host HOST                  the rabbitMQ broker IP address (default: 127.0.0.1)
            --port PORT                  the rabbitMQ broker port (default: 5672)
        -q, --queue QUEUE                a queue for publishing outgoing requests
        -e, --exchange EXCHANGE          publish to a non-default exchange - name
        -t, --type TYPE                  publish to a non-default exchange - type (e.g. :direct, :fanout, :topic)
        -r, --route ROUTE                a routing key when publishing to a non-default exchange

    Ruby options:
        -I, --include PATH               specify an additional $LOAD_PATH (may be used more than once)
            --debug                      set $DEBUG to true
            --warn                       enable warnings

    Common options:
        -h, --help
        -v, --version

## Client library

Communicating with a RackRabbit hosted service from your application can be done using the `RR` class:

    RR.get(    "myqueue",    "/path/to/resource")
    RR.post(   "myqueue",    "/path/to/resource", "content")
    RR.put(    "myqueue",    "/path/to/resource", "content")
    RR.delete( "myqueue",    "/path/to/resource")
    RR.enqueue("myqueue",    "/path/to/resource", "content")
    RR.publish("myexchange", "/path/to/resource", "content")

These methods are wrappers around a more detailed `RackRabbit::Client` class:

    client = RackRabbit::Client.new(:host => "127.0.0.1", :port => 5672, :adapter => :bunny)

    client.get(   "myqueue",     "/path/to/resource")
    client.post(  "myqueue",     "/path/to/resource", "content")
    client.put(   "myqueue",     "/path/to/resource", "content")
    client.delete("myqueue",     "/path/to/resource")
    client.enqueue("myqueue",    "/path/to/resource", "content")
    client.publish("myexchange", "/path/to/resource", "content")

    client.disconnect

More advanced options can be passed as an (optional) last parameter, e.g:

    client.post("myqueue", "/path", content.to_json, {
      :headers          => { "additional" => "header" },   # made available in the service's rack env
      :priority         => 5,                              # specify the rabbitMQ message priority
      :content_type     => "application/json",             # specify the request content_type
      :content_encoding => "utf-8"                         # specify the request content_enoding
    })

    client.publish("myexchange", "/path", "content", {
      :exchange_type    => :topic,                         # specify the rabbitMQ exchange type
      :routing_key      => "my.custom.topic",              # specify a custom rabbitMQ routing key
    })


## Supported platforms

Nothing formal yet, development is happening on MRI 2.1.2p95

TODO: test on other platforms


## TODO

 * FEATURE - allow multiple Client#reqeust in parallel (block until all have replied) - a-la-typheous
 * FEATURE - share a single reply queue across all Client#request
 * FEATURE - automatically deserialize body for known content type (e.g. json)
 * FEATURE - have exception stack trace sent back to client in development/test mode
 * BUG - avoid infinte worker spawn loop if worker fails during startup (e.g. connection to rabbit fails)
 * TEST - integration tests for worker, server, adapter/bunny, and adapter/amqp

## License

See [LICENSE](https://github.com/jakesgordon/rack-rabbit/blob/master/LICENSE) file.

## Credits

Thanks to [Jesse Storimer](http://www.jstorimer.com/) for his book
[Working with Unix Processes](http://www.jstorimer.com/products/working-with-unix-processes)

Thanks to the [Unicorn Team](http://unicorn.bogomips.org/) for providing a great
example of a preforking server.

Thanks to the [Bunny Team](http://rubybunny.info/) for providing an easy rabbitMQ Ruby client.

## Contact

If you have any ideas, feedback, requests or bug reports, you can reach me at
[jake@codeincomplete.com](mailto:jake@codeincomplete.com), or via
my website: [Code inComplete](http://codeincomplete.com).
