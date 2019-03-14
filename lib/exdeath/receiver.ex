defmodule Exdeath.Receiver do
  use GenServer

  def start_link(listen, proxy_control) do
    IO.inspect "start Exdeath Receiver"
    GenServer.start_link(__MODULE__, [listen, proxy_control], name: __MODULE__)
  end

  def init([listen, proxy_control]) do
    :gen_server.cast(self(), :accept)
    {:ok, %{listen: listen, front: nil, back: nil, proxy_control: proxy_control}}
  end

  def handle_cast(:accept, %{listen: listen, proxy_control: proxy_control}=state) do
    with {:ok, socket} <- :gen_tcp.accept(listen)
    do
      {:ok, con} = :gen_tcp.connect({192, 168, 33, 61}, 8010, [:binary, packet: 0])
      proxy_control.start_child(socket, con)
      :gen_server.cast(self(), :accept)
      {:noreply, %{state| front: socket}}
    else
      {:error, :eaddrinuse} ->
        {:stop, {:shutdown, :eaddrinuse}}
      {:error, reason} ->
        {:stop, {:shutdown, reason}}
      error ->
        {:stop, {:shutdown, error}}
    end
  end
end
