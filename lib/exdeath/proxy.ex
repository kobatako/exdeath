defmodule Exdeath.Proxy do
  use GenServer
  alias Exdeath.Cluster

  def start_link(listen, cluster, pid) do
    GenServer.start_link(__MODULE__, [listen, cluster], name: {:global, pid})
  end

  def init([listen, cluster]) do
    GenServer.cast(self(), :accept)
    {:ok, %{listen: listen, front: nil, back: nil, cluster: cluster}}
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

  def handle_info({:tcp, socket, packet}, %{front: socket, back: nil, cluster: cluster}=state) do
    node = Cluster.get_node(cluster)
    {:ok, proxy_node} = Exdeath.ProxyNode.set_connect(node)
    Exdeath.ProxyNode.send(proxy_node, packet)
    {:noreply, %{state| back: proxy_node}}
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
