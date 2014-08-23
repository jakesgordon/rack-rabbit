require_relative '../test_case'

module RackRabbit
  class TestSignals < TestCase

    #--------------------------------------------------------------------------

    def test_pop_is_fifo_queue
      signals = Signals.new
      signals.push(:TTIN)
      signals.push(:TTOU)
      signals.push(:QUIT)
      assert_equal(:TTIN, signals.pop)
      assert_equal(:TTOU, signals.pop)
      assert_equal(:QUIT, signals.pop)
    end

    #--------------------------------------------------------------------------

    def test_pop_blocks_when_queue_is_empty
      signals = Signals.new
      thread  = Thread.new { sleep 0.1 ; signals.push :QUIT }
      seconds = measure do
        sig = signals.pop
        assert_equal(:QUIT, sig)
      end
      assert_equal(true, seconds >= 0.1, 'verify we blocked for > 100ms')
      thread.join
    end

    #--------------------------------------------------------------------------

    def test_pop_blocking_can_be_timed_out
      signals = Signals.new
      seconds = measure do
        sig = signals.pop(:timeout => 0.1)
        assert_equal(:timeout, sig)
      end
      assert_equal(true, seconds >= 0.1, 'verify we blocked for > 100ms')
    end

    #--------------------------------------------------------------------------

  end # class TestSignals
end # module RackRabbit
