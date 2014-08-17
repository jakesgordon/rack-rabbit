module RackRabbit
  class Client
    class Config

      #--------------------------------------------------------------------------

      attr_reader :values
      private :values

      #--------------------------------------------------------------------------

      def initialize(options)
        @values = {}
        options.each{|key, value| send(key, value) if respond_to?(key) }
      end

      #--------------------------------------------------------------------------

      def rabbit(value = :missing)
        if value == :missing
          values[:rabbit] ||= DEFAULT_RABBIT
        elsif value.is_a?(Hash)
          rabbit.merge!(value)
        end
      end

      def app_id(value = :missing)
        if value == :missing
          values[:app_id] ||= "rack-rabbit-client"
        else
          values[:app_id] = value
        end
      end

      #--------------------------------------------------------------------------

    end # class Config
  end # class Client
end # module RackRabbit

