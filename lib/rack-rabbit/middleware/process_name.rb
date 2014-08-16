module RackRabbit
  module Middleware
    class ProcessName

      def initialize(app, default = "waiting for request")
        @app = app
        @default = default
        set_program_name(default)
      end

      def call(env)
        info = "#{env['REQUEST_METHOD']} #{env['REQUEST_PATH'] || env['PATH_INFO']}"
        set_program_name info
        status, headers, body = @app.call(env)
        set_program_name @default
        [status, headers, body]
      end

      def set_program_name(name)
        $PROGRAM_NAME = sanitize($PROGRAM_NAME.split(" -- ")[0] + " -- #{name}")[0..200]
      end

      def sanitize(value)
        if value.valid_encoding?
          value.force_encoding('utf-8')
        else
          value.chars.select(&:valid_encoding?).join.force_encoding('utf-8')
        end
      end

    end # class ProcessName
  end # module Middleware
end # module RackRabbit

