module RackRabbit
  module Helpers

    def friendly_signal(sig)
      case sig
      when :QUIT then "QUIT"
      when :INT  then "INTERRUPT"
      when :TERM then "TERMINATE"
      else
        sig
      end
    end

    def load_adapter(adapter)
      if adapter.is_a?(Symbol) || adapter.is_a?(String)
        adapter = case adapter
                  when :bunny
                    require 'rack-rabbit/adapter/bunny'
                    RackRabbit::Adapter::Bunny
                  when :amqp
                    require 'rack-rabbit/adapter/amqp'
                    RackRabbit::Adapter::AMQP
                  else
                    raise ArgumentError, "unknown rabbitMQ adapter #{adapter}"
                  end
      end
      adapter.new
    end

  end
end
