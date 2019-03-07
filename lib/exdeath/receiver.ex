defmodule Exdeath.Receiver do
  use GenServer

  def start_link(listen) do
    IO.inspect "start Exdeath Receiver"
    GenServer.start_link(__MODULE__, [listen], name: __MODULE__)
  end

  def init([listen]) do
    :gen_server.cast(self(), :accept)
    {:ok, %{listen: listen, front: nil, back: nil}}
  end

  def handle_cast(:accept, %{listen: listen}=state) do
    with {:ok, socket} <- :gen_tcp.accept(listen)
    do
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

  def handle_info({:tcp, socket, packet}, %{front: socket, back: nil}=state) do
    IO.inspect "receive front socket "
    IO.inspect socket
    packets = String.split(packet, "\r\n")
    IO.inspect packets
    {:ok, con} = :gen_tcp.connect({192, 168, 33, 61}, 8010, [:binary, packet: 0])
    :gen_tcp.send(con, packet)
    {:noreply, %{state| back: con}}
  end

  def handle_info({:tcp, socket, packet}, %{front: socket, back: back}=state) do
    IO.inspect "receive front socket "
    IO.inspect socket
    packets = String.split(packet, "\r\n")
    IO.inspect packets
    :gen_tcp.send(back, packet)
    {:noreply, state}
  end

  def handle_info({:tcp, socket, packet}, %{front: front, back: socket}=state) do
    IO.inspect "receive back socket "
    IO.inspect socket
    packets = String.split(packet, "\r\n")
    IO.inspect packets
    :gen_tcp.send(front, packet)
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
  def terminate(error, state) do
    IO.inspect "terminate"
    IO.inspect error
    state
  end
end
