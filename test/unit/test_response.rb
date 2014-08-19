require_relative '../test_case'

require 'rack-rabbit/response'

module RackRabbit
  class TestResponse < TestCase

    #--------------------------------------------------------------------------

    def test_default_response

      headers  = {}
      response = build_response(200, headers, BODY)

      assert_equal(200,     response.status)
      assert_equal(headers, response.headers)
      assert_equal(BODY,    response.body)
      assert_equal(nil,     response.content_type)
      assert_equal(nil,     response.content_encoding)
      assert_equal(true,    response.succeeded?)
      assert_equal(false,   response.failed?)
      assert_equal(BODY,    response.to_s)

    end

    #--------------------------------------------------------------------------

    def test_populated_response

      headers = {
        RackRabbit::HEADER::CONTENT_TYPE     => CONTENT_TYPE,
        RackRabbit::HEADER::CONTENT_ENCODING => CONTENT_ENCODING,
        :foo                                 => "bar"
      }
      response = build_response(200, headers, BODY)

      assert_equal(200,              response.status)
      assert_equal(headers,          response.headers)
      assert_equal(BODY,             response.body)
      assert_equal(CONTENT_TYPE,     response.content_type)
      assert_equal(CONTENT_ENCODING, response.content_encoding)
      assert_equal(true,             response.succeeded?)
      assert_equal(false,            response.failed?)
      assert_equal(BODY,             response.to_s)

    end

    #--------------------------------------------------------------------------

    def test_succeeded_and_failed

      expected_success = [ 200, 201, 202 ]
      expected_failure = [ 400, 404, 500 ]

      expected_success.each do |status|
        response = build_response(status, {}, BODY)
        assert_equal(true,  response.succeeded?, "status #{status} should be considered a success")
        assert_equal(false, response.failed?,    "status #{status} should be considered a success")
      end

      expected_failure.each do |status|
        response = build_response(status, {}, BODY)
        assert_equal(false, response.succeeded?, "status #{status} should be considered a failure")
        assert_equal(true,  response.failed?,    "status #{status} should be considered a failure")
      end

    end

    #--------------------------------------------------------------------------

  end # class TestResponse
end # module RackRabbit

