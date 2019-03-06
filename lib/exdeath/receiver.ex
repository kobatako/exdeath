defmodule Exdeath.Receiver do
  use GenServer

  def start_link() do
    IO.inspect "start Exdeath Receiver"
    ip = {0, 0, 0, 0}
    port = 4040
    GenServer.start_link(__MODULE__, [{ip, port}], name: __MODULE__)
  end

  def init([{ip, port}]) do
    with {:ok, listen_socket} <- :gen_tcp.listen(port, [:binary, packet: :raw, active: true, ip: ip])
    do
      :gen_server.cast(self(), :accept)
      {:ok, %{ip: ip, port: port, listen: listen_socket, front: nil, back: nil}}
    else
      {:error, :eaddrinuse} ->
        {:stop, {:shutdown, :eaddrinuse}}
      {:error, reason} ->
        {:stop, {:shutdown, reason}}
      error ->
        {:stop, {:shutdown, error}}
    end
  end

  def handle_cast(:accept, %{listen: listen}=state) do
    with {:ok, socket} = :gen_tcp.accept(listen)
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

  def handle_info({:tcp, socket, packet}, %{front: socket}=state) do
    IO.inspect "receive front socket "
    IO.inspect socket
    packets = String.split(packet, "\r\n")
    IO.inspect packets
    {:ok, con} = :gen_tcp.connect({192, 168, 33, 61}, 8010, [:binary, packet: 0])
    :gen_tcp.send(con, packet)
    {:noreply, %{state| back: con}}
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
