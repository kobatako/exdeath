defmodule Exdeth.Proxy do
  use GenServer

  def start_link(front, back) do
    IO.inspect "start Exdeath Proxy"
    :gen_tcp.controlling_process(front, self())
    :gen_tcp.controlling_process(back, self())
    GenServer.start_link(__MODULE__, [front, back], name: __MODULE__)
  end

  def init([front, back]) do
    {:ok, %{front: front, back: back}}
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
