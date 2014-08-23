require_relative '../test_case'

require 'rack-rabbit/handler'

module RackRabbit
  class TestHandler < TestCase

    #--------------------------------------------------------------------------

    def test_handle_message

      handler = build_handler
      message = build_message

      response = handler.handle(message)

      assert_equal(200,           response.status)
      assert_equal({},            response.headers)
      assert_equal("Hello World", response.body)
      
    end

    #--------------------------------------------------------------------------

    def test_handle_GET

      handler = build_handler(:rack_file => MIRROR_RACK_APP)
      message = build_message(:method => :GET, :path => "/my/path?foo=bar", :body => "hello")

      response = handler.handle(message)
      mirror   = JSON.parse(response.body)

      assert_equal(200,        response.status)
      assert_equal("GET",      mirror["method"])
      assert_equal("/my/path", mirror["path"])
      assert_equal("bar",      mirror["params"]["foo"])
      assert_equal("hello",    mirror["body"])

    end

    #--------------------------------------------------------------------------

    def test_handle_POST

      handler  = build_handler(:rack_file => MIRROR_RACK_APP)
      message  = build_message(:method => :POST, :path => "/my/path?foo=bar", :body => "hello")

      response = handler.handle(message)
      mirror   = JSON.parse(response.body)

      assert_equal(200,        response.status)
      assert_equal("POST",     mirror["method"])
      assert_equal("/my/path", mirror["path"])
      assert_equal("bar",      mirror["params"]["foo"])
      assert_equal("hello",    mirror["body"])

    end

    #--------------------------------------------------------------------------

    def test_handle_POST_form_data

      handler  = build_handler(:rack_file => MIRROR_RACK_APP)
      message  = build_message(:method => :POST, :path => "/my/path", :body => "foo=bar", :content_type => CONTENT::FORM_URLENCODED)

      response = handler.handle(message)
      mirror   = JSON.parse(response.body)

      assert_equal(200,        response.status)
      assert_equal("POST",     mirror["method"])
      assert_equal("/my/path", mirror["path"])
      assert_equal("bar",      mirror["params"]["foo"])
      assert_equal("foo=bar",  mirror["body"])

    end

    #--------------------------------------------------------------------------

    def test_handle_message_that_causes_rack_app_to_raise_an_exception

      handler  = build_handler(:rack_file => ERROR_RACK_APP)
      message  = build_message
      response = handler.handle(message)

      assert_equal(500,                     response.status)
      assert_equal("Internal Server Error", response.body)
      assert_equal({},                      response.headers)

    end

    #--------------------------------------------------------------------------

  end # class TestHandler
end # module RackRabbit
