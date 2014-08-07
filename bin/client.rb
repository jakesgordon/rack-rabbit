#!/usr/bin/env ruby
# encoding: utf-8
#
# TEMPORARY HACK client script for testing request/response pattern with rack-rabbit hosted servers
#
# TODO: rewrite this as a real RackRabbit::Client library (+ executable) and support all patterns
#
#  - Req/Response (GET/POST/PUT/HEAD/DELETE)
#  - Worker (ENQUEUE)
#  - Pub/Sub (PUBLISH)
#

require "bunny"
require "json"

conn = Bunny.new
conn.start

queue       = "rpc"
path        = ARGV[0]
channel     = conn.create_channel
exchange    = channel.default_exchange
reply_queue = channel.queue("", :exclusive => true)
id          = "#{rand}#{rand}#{rand}"
lock        = Mutex.new
condition   = ConditionVariable.new
response    = nil

reply_queue.subscribe do |delivery_info, properties, payload|
  if properties[:correlation_id] == id
    response = payload
    lock.synchronize { condition.signal }
  end
end

exchange.publish("",
  :message_id       => id,
  :app_id           => 'myapp',
  :priority         => 5,
  :routing_key      => queue,
  :reply_to         => reply_queue.name,
  :type             => 'GET',
  :content_type     => 'text/plain; charset = "utf-8"',
  :content_encoding => 'utf-8',
  :timestamp        => Time.now.to_i,
  :headers          => {
    :path  => path
  }
)

lock.synchronize { condition.wait(lock) }

if response.nil?
  puts "TIMEOUT"
else
  puts response
end

