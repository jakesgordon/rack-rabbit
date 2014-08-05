module RackRabbit

  class Config

    def initialize(rackup, options)
      options[:rackup] = rackup
      @options = options
      raise ArgumentError, "missing rackup file #{rackup}" unless File.readable?(rackup)
    end

    def self.declare_option(name)
      define_method(name) do
        @options[name] || defaults[name]
      end
    end

    declare_option :rackup
    declare_option :workers
    declare_option :min_workers
    declare_option :max_workers
    declare_option :queue
    declare_option :application_id

    def defaults
      @defaults ||= {
        :rackup         => 'config.ru',
        :workers        => 2,
        :min_workers    => 1,
        :max_workers    => 100,
        :queue          => 'rack-rabbit',
        :application_id => 'rack-rabbit'
      }
    end

  end

end
