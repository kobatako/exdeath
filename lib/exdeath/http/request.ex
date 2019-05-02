defmodule Exdeath.Http.Request do
  @moduledoc """
  http request encode, decode and more.
  operate on the value of http reqeust.
  """

  alias Exdeath.Http.Request

  defstruct method: "", path: "", query: %{}, fragment: "", version: "", header: %{}

  @doc """
  encode http request header
  """
  def encode(format) do
    String.split(format, "\r\n") |> parse
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

    request <> "\r\n" <> header <> "\r\n"
  end

  @doc """
  parse http request
  """
  def parse([request| headers]) do
    parse_request(request)
    |> Map.put(:header, parse_header(headers))
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
