defmodule Exdeath.Receiver do
  use GenServer

  def start_link() do
    IO.inspect "start Exdeath Receiver"
    ip = {127, 0, 0, 1}
    port = 4040
    GenServer.start_link(__MODULE__, [ip, port], name: __MODULE__)
  end

  def init([ip, port]) do
    {:ok, listen_socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: true, ip: ip])
    {:ok, socket} = :gen_tcp.accept(listen_socket)
    {:ok, %{ip: ip, port: port, socket: socket}}
  end

  def handle_info({:tcp, _socket, packet}, state) do
    IO.inspect packet
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
end
