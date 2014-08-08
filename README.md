Rack Rabbit (v0.0.1)
====================

**WARNING**: This library is in very, very early development

A preforking server for hosting RabbitMQ consumer processes as load balanced rack applications.

    $ rack-rabbit --queue myqueue --workers 4 app/config.ru

Description
-----------

Building an SOA ? Using RabbitMQ ? Want an easy way to host and load balance your consumers ?

RackRabbit will...

  * create, and manage, a cluster of worker processes that will each
  * subscribe to a RabbitMQ queue
  * convert the rabbitMQ message into a suitable Rack environment
  * call your Rack app to fulfil the request
  * (optionally) publish the response back to the original caller (if a `reply_to` queue was provided)

The goal is to support a RabbitMQ-based SOA architecture that has multiple message passing patterns:

  * Synchronous Request/Response a-la-HTTP (e.g. GET/POST/PUT/HEAD/DELETE)
  * Asynchronous Worker queue (e.g. ENQUEUE)
  * Asynchronous PubSub (e.g. PUBLISH)
  * Asynchronous Broadcast (e.g. BROADCAST)

Installation
------------

Eventually, installation will be via rubygems:

    $ gem install rack-rabbit

... but since the gem has not been officially published yet, for now you need to build it yourself:

    $ git clone https://github.com/jakesgordon/rack-rabbit
    $ cd rack-rabbit
    $ bundle install
    $ build rack-rabbit.gemspec
    $ gem install rack-rabbit.gem

Usage
-----

Use the `rack-rabbit` command line script to host your Rack app in a preforking
server that subscribes to a RabbitMQ queue

    $ rack-rabbit --help

    Usage: rack-rabbit [options] rack-file
        -h, --help
        -v, --version
        -c, --config CONFIG         specify the rack-rabbit configuration file
        -q, --queue  QUEUE          specify the queue to subscribe for incoming requests
        -w, --workers COUNT         specify the number of worker processes
        -l, --log-level LEVEL       specify the log level for rack rabbit output

Examples:

    $ rack-rabbit app/config.ru
    $ rack-rabbit app/config.ru --queue app.queue --workers 4
    $ rack-rabbit app/config.ru --config app/config/rack-rabbit.conf.rb

Configuration
-------------

Detailed RackRabbit configuration can be provided by an external config file using the `--config` option

    # set the Rack application to be used to handle messages (default 'config.ru'):
    rack_file 'app/config.ru'

    # set the queue to subscribe to (default 'rack-rabbit'):
    queue 'app.queue'

    # set the initial number of worker processes (default 2):
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
    #
    app_id 'My Application'

    # use a different rabbitMQ client adapter (default: RackRabbit::Client::Bunny)
    client RackRabbit::Client::AMQP

Client Library
--------------

TODO: build a little rabbitMQ client to support different message patterns that the workers can consume

  * Synchronous Request/Response a-la-HTTP (e.g. GET/POST/PUT/HEAD/DELETE)
  * Asynchronous Worker queue (e.g. ENQUEUE)
  * Asynchronous PubSub (e.g. PUBLISH)
  * Asynchronous Broadcast (e.g. BROADCAST)

Signals
-------

Signals should be sent to the master process

  * HUP - reload the RackRabbit config file and gracefully restart all workers
  * QUIT - graceful shutdown, waits for workers to finish their current request before finishing
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

Supported Platforms
-------------------

Nothing formal yet, development is happening on MRI 2.1.2p95

TODO
----

 * provide AMQP gem client adapter
 * client library
 * daemonizing
 * testing
 * platform support

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
