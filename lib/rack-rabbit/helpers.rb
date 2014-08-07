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

  end
end
