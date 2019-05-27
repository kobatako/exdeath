defmodule Exdeath.Http.Request do
  @moduledoc """
  http request encode, decode and more.
  operate on the value of http reqeust.
  """

  alias Exdeath.Http.Request

  defstruct method: "", path: "", query: %{}, fragment: "", version: "", header: %{}, body: ""

  @doc """
  encode http request header
  """
  def encode(format, true) do
    String.split(format, "\r\n") |> parse
  end
  def encode(format, false) do
    String.split(format, "\r\n")
  end

  @doc """
  decode http request header
  """
  def decode(format) do
    request = format.method <> " " <> format.path <> " " <> format.version
    header = for {key, value} <- format.header do
      key <> ": " <> value
    end
    |> Enum.reduce("", fn head, acc -> head <> "\r\n" <> acc end)

    request <> "\r\n" <> header <> "\r\n" <> Enum.join(format.body, "\r\n")
  end

  @doc """
  parse http request
  """
  def parse([request| headers]) do
    {split_headers, body} = split_header_body(headers, [])
    parse_request(request)
    |> Map.put(:header, parse_header(split_headers))
    |> Map.put(:body, body)
    |> Map.put(:body_len, body_length(body))
  end

  @doc """
  add http header
  if key exist in http header, add value.
  if key not eixst in http header, create key value.
  """
  def add_header(request, key, value) when is_binary(key) and is_binary(value) do
    if Map.has_key?(request, key) do
      update_in(request.header, fn header ->
        tmp_value = request.header[key]
        Map.put(header, key, "#{tmp_value}; #{value}")
      end)
    else
      update_in(request.header, fn header ->
        Map.put(header, String.downcase(key),  String.trim(value))
      end)
    end
  end

  @doc """
  set http header
  add new key and value to http header.
  if key eixst in http header, overwrite value.
  """
  def set_header(request, key, value) when is_binary(key) and is_binary(value) do
    update_in(request.header, fn header ->
      Map.put(header, String.downcase(key),  String.trim(value))
    end)
  end

  def set_header(_, _, _) do
    {:error, "not match header format. header key is string only."}
  end

  @doc """
  the key of http header overwrite the one of host.
  """
  def set_host(request, socket) do
    {:ok, ip, port} = fetch_ip(:inet.peername(socket))
    Request.set_header(request, "host", ip <> ":" <> Integer.to_string(port))
  end

  @doc """
  x-forwarded key set to http header.
  """
  def set_forwarded(request, socket) do
    {:ok, for_ip, _} = fetch_ip(:inet.peername(socket))
    {:ok, by_ip, _} = fetch_ip(:inet.sockname(socket))
    host = request.header["host"]

    Request.add_header(request, "x-forwarded-for", for_ip)
    |> Request.add_header("x-forwarded-by", by_ip)
    |> Request.set_header("x-forwarded-host", host)
  end

  @doc """
  fetch content by header
  """
  def fetch_content(header) do
    length = Map.get(header, "content-length", 0)
    type = fetch_content_type(header)
    %{length: length, type: type}
  end

  @doc """
  match multipart boundary
  """
  def match_multipart_boundary(body, boundary) do
    search_list(body, "--" <> boundary <> "--")
  end

  defp search_list([], value) do
    false
  end
  defp search_list([value| _], value) do
    true
  end
  defp search_list([_| tail], value) do
    search_list(tail, value)
  end

  defp fetch_content_type(header) do
    type = Map.get(header, "content-type", "")
    types = String.split(type, ";")
    split_content_type(types)
  end
  defp split_content_type([type| args]) do
    args = parse_content_type_argument(args, %{})
    %{type: type, args: args}
  end

  defp parse_content_type_argument([], args) do
    args
  end
  defp parse_content_type_argument([head| tail], args) do
    [key, value] = String.split(head, "=")
    args = Map.put(args, String.trim(key), value)
    parse_content_type_argument(tail, args)
  end

  defp body_length(body) do
    Enum.join(body, "\r\n")
    |> String.length()
  end

  defp split_header_body([""| [""]], header) do
    {header, []}
  end
  defp split_header_body([""| tail], header) do
    {header, tail}
  end

  defp split_header_body([head| tail], header) do
    split_header_body(tail, [head| header])
  end

  defp parse_request(request) do
    String.split(request, " ") |> List.to_tuple |> parse_request_format
  end

  defp parse_request_format({method, path, version}) do
    [path| query] = String.split(path, "?", parts: 2, trim: true)
    {queries, fragment} = split_query(query)
    %Request{method: method, path: path, query: queries, fragment: fragment, version: version}
  end

  defp split_query([]) do
    {%{}, ""}
  end

  defp split_query([query]) do
    [query| fragment] = String.split(query, "#", parts: 2, trim: true)
    queries = parse_query(query)
    fragment = parse_fragment(fragment)
    {queries, fragment}
  end

  defp parse_fragment([]) do
    ""
  end

  defp parse_fragment([fragment]) do
    fragment
  end

  defp parse_query([]) do
    %{}
  end

  defp parse_query([query_string]=query) when is_list(query) do
    String.split(query_string, "&")
    |> Enum.map(&(String.split(&1, "=") |> List.to_tuple()))
    |> Enum.reduce(%{}, fn {key, value}, acc -> Map.merge(acc, %{String.downcase(key) => String.trim(value)}) end)
  end

  defp parse_query(query) when is_binary(query) do
    String.split(query, "&")
    |> Enum.map(&(String.split(&1, "=") |> List.to_tuple()))
    |> Enum.reduce(%{}, fn {key, value}, acc -> Map.merge(acc, %{String.downcase(key) => String.trim(value)}) end)
  end

  defp parse_query([]) do
    %{}
  end

  defp parse_header(headers) do
    Enum.map(headers, fn head -> String.split(head, ":", parts: 2, trim: true) |> List.to_tuple end)
    |> Enum.filter(fn x -> {} != x end)
    |> Enum.reduce(%{}, fn {key, value}, acc -> Map.merge(acc, %{String.downcase(key) => String.trim(value)}) end)
  end

  defp fetch_ip({:ok, {ip, port}}) do
    {:ok, ip} = ip_to_string(ip)
    {:ok, ip, port}
  end

  defp ip_to_string({i1, i2, i3, i4}) do
    {:ok, "#{i1}.#{i2}.#{i3}.#{i4}"}
  end

  defp ip_to_string(_) do
    {:error, "not match ip format."}
  end
end
