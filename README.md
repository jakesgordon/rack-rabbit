Rack Rabbit (v0.1.0)
====================

A forking server for hosting rabbitMQ consumer processes as load balanced rack applications.

    $ rack-rabbit --queue myqueue --workers 4 app/config.ru

Description
-----------

Building an SOA with rabbitMQ? Want to host and load balance your consumer processes?

RackRabbit will...

  * Manage a cluster of worker processes that will each...
  * Subscribe to a queue (or an exchange)
  * Convert incoming messages into a suitable Rack environment
  * Call your Rack app to handle the message
  * Publish a reply back to the original caller (if `reply_to` was provided)

RackRabbit will support a rabbitMQ-based SOA with multiple message passing patterns:

  * Synchronous Request/Response (e.g. GET/POST/PUT/DELETE)
  * Asynchronous Worker queue    (e.g. ENQUEUE)
  * Asynchronous PubSub          (e.g. PUBLISH)

Installation
------------

Install a rabbitMQ server if necessary:

    $ sudo apt-get install rabbitmq-server

Update your Gemfile to include RackRabbit and your preferred rabbitMQ client library

    gem bunny,       "~> 1.4"             # or an alternative such as AMQP or march-hare
    gem rack-rabbit, "~> 0.1"


Getting started by example
--------------------------

You can use RackRabbit + Sinatra (or any rack app) to easily host an AMQP-based SOA in the same way
that you might use Unicorn + Sinatra to host an HTTP-based SOA.

Imagine a simple sinatra application in `config.ru`:

    require 'sinatra/base'

    class MyApp < Sinatra::Base

      get "/hello" do
        "Hello World"
      end

      post "/submit" do
        "Submitted #{request.body.read}"
      end

    end

    run MyApp

You can now host and load balance this application using `rack-rabbit`:

    $ rack-rabbit --queue myqueue --workers 4

Ensure the worker processes are running:

    $ ps xawf | grep rack-rabbit
    15714 pts/4    Sl+    0:00  |   \_ ruby rack-rabbit --queue myqueue --workers 4 config.ru
    15716 pts/4    Sl+    0:00  |       \_ rack-rabbit -- waiting for request
    15718 pts/4    Sl+    0:00  |       \_ rack-rabbit -- waiting for request
    15721 pts/4    Sl+    0:00  |       \_ rack-rabbit -- waiting for request
    15723 pts/4    Sl+    0:00  |       \_ rack-rabbit -- waiting for request

You can connect to the worker from the command line using the `rr` command:

    $ rr request -q myqueue /hello                    # synchronous GET request/response
    Hello World

    $ rr request -q myqueue POST /submit "data"       # synchronous POST request/response
    Submitted some data

    $ rr enqueue -q myqueue /do/work "data"           # asynchronous ENQUEUE to a worker queue

    $ rr publish -e myexchange /fire/event            # asynchronous PUBLISH to a pub/sub exchange


You can also connect to the worker from your applications using the `RackRabbit::Client` class.

    require 'rack-rabbit/client'

    a = RackRabbit::Client.get     :myqueue,    "/hello"              # -> "Hello World"
    b = RackRabbit::Client.post    :myqueue,    "/sumbit",  "data"    # -> "Submitted data"
        RackRabbit::Client.enqueue :myqueue,    "/do/work", "data"    # async worker queue
        RackRabbit::Client.publish :myexchange, "/fire/event"         # async pub/sub


HTTP vs AMQP based SOA
----------------------

TODO: describe difference between using Unicorn for HTTP-based SOA and RackRabbit for AMQP-based SOA


Server Usage
------------

Use the `rack-rabbit` command line script to host your Rack app in a preforking server that
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



Server Configuration
--------------------

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


Signals
-------

Signals should be sent to the master process

  * HUP - reload the RackRabbit config file and gracefully restart all workers
  * QUIT - graceful shutdown, waits for workers to complete handling of their current message before finishing
  * TERM - quick shutdown kills all workers immediately
  * INT  - quick shutdown kills all workers immediately
  * TTIN - increase the number of worker processes by one
  * TTOU - decrease the number of worker processes by one

Forking Worker Processes
------------------------

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

RabbitMQ Acknowledgements
-------------------------

TODO: document :ack and :reject support

Client Library
--------------

Posting a message to a RackRabbit hosted server can be done using any rabbitMQ client library, but
is easiest using the built in `RackRabbit::Client`...

TODO: document RackRabbit::Client

Supported Platforms
-------------------

Nothing formal yet, development is happening on MRI 2.1.2p95

TODO: test on other platforms


TODO
----

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

License
-------

See [LICENSE](https://github.com/jakesgordon/rack-rabbit/blob/master/LICENSE) file.

Credits
-------

Thanks to [Jesse Storimer](http://www.jstorimer.com/) for his book
[Working with Unix Processes](http://www.jstorimer.com/products/working-with-unix-processes)

Thanks to the [Unicorn Team](http://unicorn.bogomips.org/) for providing a great
example of a preforking server.

Thanks to the [Bunny Team](http://rubybunny.info/) for providing an easy rabbitMQ Ruby client.

Contact
-------

If you have any ideas, feedback, requests or bug reports, you can reach me at
[jake@codeincomplete.com](mailto:jake@codeincomplete.com), or via
my website: [Code inComplete](http://codeincomplete.com).
