defmodule Exdeath.Http.RequestTest do
  use ExUnit.Case

  alias Exdeath.Http.Request

  test "header request" do
    header = "GET / HTTP/1.1\r\nHost: 192.168.33.101:4040\r\nConnection: keep-alive\r\nCache-Control: max-age=0\r\nUpgrade-Insecure-Requests: 1\r\nUser-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36\r\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3\r\nAccept-Encoding: gzip, deflate\r\nAccept-Language: ja,en;q=0.9\r\n\r\n"
    request = Request.encode(header)

    assert "GET" == request.method
    assert "/" == request.path
    assert "HTTP/1.1" == request.version
    assert "192.168.33.101:4040" == request.header["host"]
    assert "keep-alive" == request.header["connection"]
    assert "max-age=0" == request.header["cache-control"]
  end

  test "set header" do
    header = "GET / HTTP/1.1\r\nHost: 192.168.33.101:4040\r\nConnection: keep-alive\r\nCache-Control: max-age=0\r\nUpgrade-Insecure-Requests: 1\r\nUser-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36\r\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3\r\nAccept-Encoding: gzip, deflate\r\nAccept-Language: ja,en;q=0.9\r\n\r\n"

    request = Request.encode(header)
    |> Request.set_header("Test-Header", "test-value")

    assert "test-value" == request.header["test-header"]

    # error header request
    assert {:error, "not match header format. header key is string only."}
      == Request.set_header(request, 1, 1)
    assert {:error, "not match header format. header key is string only."}
      == Request.set_header(request, 'a', 1)
    assert {:error, "not match header format. header key is string only."}
      == Request.set_header(request, :a, 1)
  end
end
