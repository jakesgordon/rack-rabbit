require_relative '../../test_case'

require 'rack-rabbit/middleware/program_name'

module RackRabbit
  class TestProgramName < TestCase

    #--------------------------------------------------------------------------

    def test_program_name_changes_during_rack_handler
      with_program_name("rr") do

        assert_equal("rr", $PROGRAM_NAME)

        during = nil
        app    = lambda{|env| during = $PROGRAM_NAME }

        middleware = RackRabbit::Middleware::ProgramName.new(app, "default")
        assert_equal("rr -- default", $PROGRAM_NAME)

        middleware.call('REQUEST_METHOD' => 'method', 'REQUEST_PATH' => 'path')
        assert_equal("rr -- default", $PROGRAM_NAME)
        assert_equal("rr -- method path", during)

      end
    end

    #--------------------------------------------------------------------------

  end # class TestProgramName
end # module RackRabbit

