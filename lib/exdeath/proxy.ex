defmodule Exdeath.Proxy do
  use GenServer
  def start_link(listen, hosts, pid) do
    GenServer.start_link(__MODULE__, [listen, hosts], name: {:global, pid})
  end

  def init([listen, hosts]) do
    GenServer.cast(self(), :accept)
    {:ok, %{listen: listen, front: nil, back: nil, hosts: hosts}}
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

  def handle_info({:tcp, socket, packet}, %{front: socket, back: nil, hosts: [host| _]}=state) do
    {:ok, proxy_host} = Exdeath.ProxyNode.set_connect(host)
    Exdeath.ProxyNode.send(proxy_host, packet)
    {:noreply, %{state| back: proxy_host}}
  end

  def handle_info({:tcp, socket, packet}, %{front: socket, back: back}=state) do
    Exdeath.ProxyNode.send(back, packet)
    {:noreply, state}
  end

  def handle_info({:tcp, socket, packet}, %{front: front, back: %{conn: socket}}=state) do
    :gen_tcp.send(front, packet)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, socket}, %{front: socket, back: nil}=state) do
    {:stop, :shutdown, state}
  end
  def handle_info({:tcp_closed, socket}, %{front: socket, back: back}=state) do
    Exdeath.ProxyNode.close_connect(back)
    {:stop, :shutdown, state}
  end

  def handle_info({:tcp_closed, socket}, %{front: nil, back: socket}=state) do
    {:stop, :shutdown, state}
  end
  def handle_info({:tcp_closed, socket}, %{front: front, back: %{conn: socket}}=state) do
    :gen_tcp.close(front)
    {:stop, :shutdown, state}
  end

  def terminate(:shutdown, state) do
    state
  end

  def terminate({:shutdown, :eaddrinuse}, state) do
    state
  end

  def terminate(_, state) do
    state
  end
end
