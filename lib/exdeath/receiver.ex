defmodule Exdeath.Receiver do
  use GenServer

  def start_link() do
    IO.inspect "start Exdeath Receiver"
    ip = {127, 0, 0, 1}
    port = 4040
    GenServer.start_link(__MODULE__, [ip, port], name: __MODULE__)
  end

  def init([ip, port]) do
    with {:ok, listen_socket} <- :gen_tcp.listen(port, [:binary, packet: :raw, active: true, ip: ip]),
        {:ok, socket} = :gen_tcp.accept(listen_socket)
    do
      {:ok, %{ip: ip, port: port, socket: socket}}
    else
      {:error, :eaddrinuse} ->
        {:stop, {:shutdown, :eaddrinuse}}
      {:error, reason} ->
        {:stop, {:shutdown, reason}}
      error ->
        {:stop, :shutdown}
    end
  end

  def handle_info({:tcp, _socket, packet}, state) do
    packets = String.split(packet, " ")
    IO.inspect packets
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _socket}, state) do
    IO.inspect "tcp closed socket"
    {:stop, :shutdown, state}
  end

  def terminate(:shutdown, state) do
    IO.inspect "terminate shutdown"
    state
  end

  def terminate({:shutdown, :eaddrinuse}, state) do
    IO.inspect "terminate eaddrinuse"
    state
  end
end
