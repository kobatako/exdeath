defmodule Exdeath.Proxy do
  use GenServer
  def start_link(listen, pid) do
    GenServer.start_link(__MODULE__, [listen], name: {:global, pid})
  end

  def init([listen]) do
    GenServer.cast(self(), :accept)
    {:ok, %{listen: listen, front: nil, back: nil}}
end

  def handle_cast(:accept, %{listen: listen}=state) do
    with {:ok, socket} <- :gen_tcp.accept(listen)
    do
      :gen_tcp.controlling_process(socket, self())
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
    packets = String.split(packet, "\r\n")
    {:ok, con} = :gen_tcp.connect({192, 168, 30, 20}, 8000, [:binary, packet: 0])
    :gen_tcp.send(con, packet)
    {:noreply, %{state| back: con}}
  end

  def handle_info({:tcp, socket, packet}, %{front: socket, back: back}=state) do
    packets = String.split(packet, "\r\n")
    :gen_tcp.send(back, packet)
    {:noreply, state}
  end

  def handle_info({:tcp, socket, packet}, %{front: front, back: socket}=state) do
    packets = String.split(packet, "\r\n")
    :gen_tcp.send(front, packet)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, socket}, %{front: socket, back: nil}=state) do
    {:stop, :shutdown, state}
  end
  def handle_info({:tcp_closed, socket}, %{front: socket, back: back}=state) do
    :gen_tcp.close(back)
    {:stop, :shutdown, state}
  end

  def handle_info({:tcp_closed, socket}, %{front: nil, back: socket}=state) do
    {:stop, :shutdown, state}
  end
  def handle_info({:tcp_closed, socket}, %{front: front, back: socket}=state) do
    :gen_tcp.close(front)
    {:stop, :shutdown, state}
  end

  def terminate(:shutdown, state) do
    state
  end

  def terminate({:shutdown, :eaddrinuse}, state) do
    state
  end
  def terminate(error, state) do
    state
  end
end
