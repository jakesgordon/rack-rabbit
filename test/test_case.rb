require 'minitest/autorun'

module RackRabbit
  class TestCase < Minitest::Unit::TestCase

    SAMPLE_CONFIG   = File.expand_path("examples/rack-rabbit.conf", File.dirname(__FILE__))
    SIMPLE_RACK_APP = File.expand_path("examples/simple.ru",        File.dirname(__FILE__))

  end
end
