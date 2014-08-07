Rack Rabbit (v0.0.1)
====================

**WARNING**: This library is in very, very early development

A Unicorn-style preforking server for hosting RabbitMQ consumer processes as load balanced rack applications.

    $ rack-rabbit --queue myqueue --workers 4 app/config.ru

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
============

Eventually, installation will be via rubygems:

    $ gem install rack-rabbit

... but since the gem has not been officially published yet, for now you need to build it yourself:

    $ git clone https://github.com/jakesgordon/rack-rabbit
    $ cd rack-rabbit
    $ bundle install
    $ build rack-rabbit.gemspec
    $ gem install rack-rabbit.gem

Usage
=====

Use the `rack-rabbit` command line script to host your Rack app in a preforking
server that subscribes to a RabbitMQ queue

    $ rack-rabbit --queue myqueue --workers 4 app/config.ru

Client Library
==============

TODO: build a little rabbitMQ/Bunny client to support different message patterns that the workers can consume

  * Synchronous Request/Response a-la-HTTP (e.g. GET/POST/PUT/HEAD/DELETE)
  * Asynchronous Worker queue (e.g. ENQUEUE)
  * Asynchronous PubSub (e.g. PUBLISH)
  * Asynchronous Broadcast (e.g. BROADCAST)

Configuration
=============

TODO: support (and document) a detailed configuration file

Signals
=======

TODO: document signals

  * QUIT - quit
  * TERM - terminate
  * INT  - interrupt
  * TTIN - increase worker count
  * TTOU - decrease worker count

Supported Platforms
===================

Nothing formal yet, development is happening on MRI 2.1.2p95

TODO
====

 * better signal handling - differentiate between QUIT, TERM, and INT
 * better signal handling in workers (use similar signal Q and remove threading log hack)
 * daemonizing
 * documentation
 * testing
 * client side wrapper

License
=======

See [LICENSE](https://github.com/jakesgordon/rack-rabbit/blob/master/LICENSE) file.

Credits
=======

Thanks to [Jesse Storimer](http://www.jstorimer.com/) for his book
[Working with Unix Processes](http://www.jstorimer.com/products/working-with-unix-processes)

Thanks to the [Unicorn Team](http://unicorn.bogomips.org/) for providing a great
example of a preforking server.

Thanks to the [Bunny Team](http://rubybunny.info/) for providing an easy RabbitMQ Ruby client.

Contact
=======

If you have any ideas, feedback, requests or bug reports, you can reach me at
[jake@codeincomplete.com](mailto:jake@codeincomplete.com), or via
my website: [Code inComplete](http://codeincomplete.com).
