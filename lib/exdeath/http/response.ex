defmodule Exdeath.Http.Response do
  @moduledoc """
  """

  alias Exdeath.Http.Response

  defstruct version: "", code: "", phrase: "", header: %{}, body: ""
  def encode(packet) do
    String.split(packet, "\r\n") |> parse
  end

  def decode(format) do
    request = format.version <> " " <> Integer.to_string(format.code) <> " " <> format.phrase
    header = for {key, value} <- format.header do
      key <> ": " <> value
    end
    |> Enum.reduce("", fn head, acc -> head <> "\r\n" <> acc end)

    request <> "\r\n" <> header <> "\r\n" <> Enum.join(format.body, "\r\n")
  end

  defp parse([status| headers]) do
    {header, body} = split_header_body(headers, [])
    String.split(status, " ")
    |> parse_status
    |> Map.put(:header, parse_header(header))
    |> Map.put(:body, body)
  end

  defp parse_status([version, code| phrase]) do
    %Response{version: version, code: String.to_integer(code), phrase: Enum.join(phrase, " ")}
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

  defp parse_header(headers) do
    Enum.map(headers, fn head -> String.split(head, ":", parts: 2, trim: true) |> List.to_tuple end)
    |> Enum.filter(fn x -> {} != x end)
    |> Enum.reduce(%{}, fn {key, value}, acc -> Map.merge(acc, %{String.downcase(key) => String.trim(value)}) end)
  end
end
