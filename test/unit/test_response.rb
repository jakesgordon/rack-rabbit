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

    def test_to_s
      r1 = build_response(200, {}, BODY)
      r2 = build_response(400, {}, BODY)
      r3 = build_response(404, {}, BODY)
      r4 = build_response(500, {}, BODY)
      assert_equal(BODY,                        r1.to_s)
      assert_equal("400 Bad Request",           r2.to_s)
      assert_equal("404 Not Found",             r3.to_s)
      assert_equal("500 Internal Server Error", r4.to_s)
    end

    #--------------------------------------------------------------------------

  end # class TestResponse
end # module RackRabbit

