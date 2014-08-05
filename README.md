Rack Rabbit (v0.0.1)
====================

A Unicorn-style preforking rack-based server for hosting RabbitMQ consumer processes

This library is in early-early development (e.g. there is nothing to see here yet)

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

    rack-rabbit --queue myqueue --workers 5 config.ru

Supported Platforms
===================

Nothing formal yet, development is happening on MRI 2.1.2p95

TODO
====

 * better signal handling - differentiate between QUIT, TERM, and INT
 * better signal handling in workers (use similar signal Q and remove threading log hack)
 * after fork hook intergration points
 * daemonizing
 * config file
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
