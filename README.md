# Rack Rabbit (v0.1.0)

A forking server for hosting rabbitMQ consumer processes as load balanced rack applications.

    $ rack-rabbit --queue myqueue --workers 4 app/config.ru

## Contents

  - [Summary](#summary)
  - [Installation](#installation)
  - [Getting started by example](#getting-started-by-example)
  - [Server Usage](#server-usage)
  - [Server Configuration](#server-configuration)
  - [Signals](#signals)
  - [Forking Worker Processes](#forking-worker-processes)
  - [RabbitMQ Acknowledgements](#rabbitmq-acknowledgements)
  - [Client Binary](#client-binary)
  - [Client Library](#client-library)
  - [Supported Platforms](#supported-platforms)
  - [TODO](#todo)
  - [License](#license)
  - [Credits](#credits)
  - [Contact](#contact)

## Summary

Building an SOA with rabbitMQ? Use RackRabbit to:

  * Host a cluster of worker processes that...
  * ... subscribe to a queue (or an exchange)
  * ... convert incoming messages into a suitable Rack environment
  * ... call your Rack app to handle the message
  * ... publish a reply back to the original caller (if `reply_to` was provided)

RackRabbit supports a variety of messaging patterns:

  * Synchronous Request/Response (e.g. GET/POST/PUT/DELETE)
  * Asynchronous Worker queue    (e.g. ENQUEUE)
  * Asynchronous PubSub          (e.g. PUBLISH)


What Unicorn does for HTTP services, RackRabbit can do for hosting AMQP services, and more:

|                             SOA over | HTTP            | AMQP                  |
|--------------------------------------|-----------------|-----------------------|
| Make a synchronous request/response  | Unicorn         | rabbitMQ + RackRabbit |
| Asynchronous worker queue            | Redis + Resque  | rabbitMQ + RackRabbit |
| Asynchronous publish/subscribe       | Redis           | rabbitMQ + RackRabbit |


## Installation

Install a rabbitMQ server if necessary:

    $ sudo apt-get install rabbitmq-server

Update your Gemfile to include RackRabbit and your preferred rabbitMQ client library

    gem bunny,       "~> 1.4"             # or an alternative such as AMQP or march-hare
    gem rack-rabbit, "~> 0.1"


## Getting started by example

You can use RackRabbit to easily host an AMQP-based service as a rack application in the same way
that you might use Unicorn to host an HTTP-based service.

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
    
You can now host and load balance this service using `rack-rabbit`:

    $ rack-rabbit --queue myqueue --workers 4  config.ru

Ensure the worker processes are running:

    $ ps xawf | grep rack-rabbit
    15714 pts/4    Sl+    0:00  |   \_ ruby rack-rabbit --queue myqueue --workers 4  config.ru
    15716 pts/4    Sl+    0:00  |       \_ rack-rabbit -- waiting for request
    15718 pts/4    Sl+    0:00  |       \_ rack-rabbit -- waiting for request
    15721 pts/4    Sl+    0:00  |       \_ rack-rabbit -- waiting for request
    15723 pts/4    Sl+    0:00  |       \_ rack-rabbit -- waiting for request

You can connect to the worker from the command line using the `rr` command:

    $ rr -q myqueue /hello                    # synchronous GET request/response
    GET /hello

    $ rr -q myqueue POST /submit "data"       # synchronous POST request/response
    POST /submit data


You can also connect to the worker from your applications using the `RackRabbit::Client` class.

    require 'rack-rabbit/client'

    RackRabbit::Client.get  :myqueue, "/hello"             # returns "GET /hello"
    RackRabbit::Client.post :myqueue, "/sumbit", "data"    # returns "POST /submit data"


See [EXAMPLES.md](https://github.com/jakesgordon/rack-rabbit/blob/master/EXAMPLES.md) for many more detailed examples.

## Server Usage

Use the `rack-rabbit` command line script to host your Rack app in a forking server that
subscribes either to a named queue or an exchange.

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



## Server Configuration

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

    # enable rabbitMQ acknowledgements
    ack true

    # set the initial number of worker processes (default: 1):
    workers 8

    # set the minimum number of worker processes (default: 1):
    min_workers 1

    # set the maximum number of worker processes (default: 100):
    max_workers 16

    # preload the Rack app in the server for faster worker forking (default: false):
    preload_app true

    # daemonize the process
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

## Forking Worker Processes

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

## RabbitMQ Acknowledgements

TODO: document :ack and :reject support

## Client Binary

Posting a message to a RackRabbit hosted server can be done using the `rr` binary:

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

## Client Library

Posting a message to a RackRabbit hosted server from within your application can be done using
the `RackRabbit::Client` library...

TODO: document RackRabbit::Client


## Supported Platforms

Nothing formal yet, development is happening on MRI 2.1.2p95

TODO: test on other platforms


## TODO

 * avoid infinite spawn worker loop if worker fails during startup (e.g. connection to rabbit fails)
 * allow multiple synchronous req/response in parallel (block until all have replied)
 * allow a single reply queue to be shared across client requests
 * have exception callstacks sent back to client (in development mode only)
 * automatically deserialize body into hash if content type is json ?

 * more testing
   - worker
   - server
   - adapter/bunny
   - adapter/amqp

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
