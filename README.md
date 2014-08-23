Rack Rabbit (v0.0.1)
====================

**WARNING**: This library is in very, very early development

A preforking server for hosting RabbitMQ consumer processes as load balanced rack applications.

    $ rack-rabbit --queue myqueue --workers 4 app/config.ru

Description
-----------

Building an SOA with RabbitMQ ? Want an easy way to host and load balance your consumer processes ?

RackRabbit will...

  * Create, and manage, a cluster of worker processes that will each...
  * Subscribe to a queue
  * Convert incoming messages into a suitable Rack environment
  * Call your Rack app to handle the message
  * Publish a reply back to the original caller (if `reply_to` queue was provided)

The goal is to support a RabbitMQ-based SOA with multiple message passing patterns:

  * Synchronous Request/Response (e.g. GET/POST/PUT/DELETE)
  * Asynchronous Worker queue
  * Asynchronous PubSub

Installation
------------

Eventually, installation will be via rubygems:

    $ gem install bunny          # or an alternative rabbitMQ cient library (e.g. AMQP)
    $ gem install rack-rabbit

... but since the gem has not been officially published yet, for now you need to build it yourself:

    $ git clone https://github.com/jakesgordon/rack-rabbit
    $ cd rack-rabbit
    $ bundle install
    $ build rack-rabbit.gemspec
    $ gem install rack-rabbit.gem

Don't forget to install a rabbitMQ server:

    $ sudo apt-get install rabbitmq-server

Getting Started
---------------

You can use RackRabbit + Sinatra (or any rack app) to easily host an AMQP-based SOA in the same way
that you might use Unicorn + Sinatra to host an HTTP-based SOA.

Imagine a simple sinatra application in `app.rb`:

    require 'sinatra/base'

    class MyApp < Sinatra::Base

      get "/hello" do
        "Hello World"
      end

      post "/submit" do
        "Submitted #{request.body.read}"
      end

    end

... and a rack configuration file `config.ru`:

    require_relative 'app'
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

You can connect to the worker from your client applications using the `RackRabbit::Client`:

    require 'rack-rabbit/client'

    client = RackRabbit::Client.new(:queue => :myqueue)

    foo = client.get  "/hello"                 # -> "Hello World"
    bar = client.post "/submit", "some data"   # -> "Submitted some data"

    client.disconnect

You can also connect to the worker from the command line using the `request` client binary:

    $ request -q myqueue GET /hello
    Hello World

    $ request -q myqueue POST /submit "some data"
    Submitted some data


HTTP vs AMQP based SOA
----------------------

TODO: describe difference between using Unicorn for HTTP-based SOA and RackRabbit for AMQP-based SOA


Server Usage
------------

Use the `rack-rabbit` command line script to host your Rack app in a preforking server that
subscribes either to a named queue or an exchange.

    $ rack-rabbit --help

    A load balanced rack server for hosting RabbitMQ consumer processes.

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
            --host HOST                  the RabbitMQ broker IP address (default: 127.0.0.1)
            --port PORT                  the RabbitMQ broker port (default: 5672)

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

Detailed RackRabbit configuration can be provided by an external config file using the `--config` option

    # set the Rack application to be used to handle messages (default 'config.ru'):
    rack_file 'app/config.ru'

    # set the RabbitMQ connection:
    rabbit :host    => '10.0.0.42',  # default '127.0.0.1'
           :port    => '1234'        # default '5672'
           :adapter => :amqp         # default :bunny

    # subscribe to a queue:
    queue 'my.queue'

    # ... or, subscribe to an exchange:
    exchange      'my.exchange'
    exchange_type :topic
    routing_key   'my.topic'

    # set the initial number of worker processes (default: 1):
    workers 8

    # set the minimum number of worker processes (default: 1):
    min_workers 1

    # set the maximum number of worker processes (default: 100):
    max_workers 16

    # preload the Rack app in the server for faster worker forking (default: false):
    preload_app true

    # set the log level for the Rack Rabbit logger (default: info)
    log_level 'debug'

    # set the Logger to used by the Rack Rabbit server and the worker Rack applications (default: Logger)
    logger MyLogger.new

    # set the app_id used to identify your application in response messages
    app_id 'my-application'

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

Client Library
--------------

Posting a message to a RackRabbit hosted server can be done using any RabbitMQ client library, but
is easiest using the built in `RackRabbit::Client`...

TODO: document RackRabbit::Client

Supported Platforms
-------------------

Nothing formal yet, development is happening on MRI 2.1.2p95

TODO
----

 * testing
   - replace DEFAULT rack app with MIRROR rack app ?
   - worker
   - server
   - client
   - adapter/bunny
   - adapter/amqp

 * better documentation
   - client
   - :ack and :reject support

 * platform support
 * MISC
   - avoid infinite spawn worker loop if worker fails during startup (e.g. connection to rabbit fails)
   - allow a single reply queue to be shared across client requests
   - allow multiple synchronous req/response in parallel (block until all have replied)
   - automatically deserialize body into hash if content type is json ?
   - have exception callstacks sent back to client (in development mode only)

License
-------

See [LICENSE](https://github.com/jakesgordon/rack-rabbit/blob/master/LICENSE) file.

Credits
-------

Thanks to [Jesse Storimer](http://www.jstorimer.com/) for his book
[Working with Unix Processes](http://www.jstorimer.com/products/working-with-unix-processes)

Thanks to the [Unicorn Team](http://unicorn.bogomips.org/) for providing a great
example of a preforking server.

Thanks to the [Bunny Team](http://rubybunny.info/) for providing an easy RabbitMQ Ruby client.

Contact
-------

If you have any ideas, feedback, requests or bug reports, you can reach me at
[jake@codeincomplete.com](mailto:jake@codeincomplete.com), or via
my website: [Code inComplete](http://codeincomplete.com).
