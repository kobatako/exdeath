defmodule Exdeath.Proxy do
  use GenServer
  alias Exdeath.Cluster
  alias Exdeath.Http.Request
  alias Exdeath.Http.Response
  alias Exdeath.Filter.CircuitBreaker

  def start_link(listen, cluster, pid) do
    GenServer.start_link(__MODULE__, [listen, cluster], name: {:global, pid})
  end

  def init([listen, cluster]) do
    GenServer.cast(self(), :accept)
    {:ok, %{listen: listen, front: nil, back: nil, cluster: cluster, content: nil, request: nil}}
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

  @doc """
  when backend is closed.
  Get destination server from Cluster.
  """
  def handle_info({:tcp, socket, packet}, %{front: socket, back: nil, cluster: cluster}=state) do
    node = Cluster.get_node(cluster)

    {:ok, proxy_node} = Exdeath.ProxyNode.set_connect(node)

    request = Request.encode(packet, true)
    |> Request.set_forwarded(socket)
    |> Request.set_host(proxy_node.conn)

    CircuitBreaker.input(request)

    content = Request.fetch_content(request.header)
    case content.type.type do
      "multipart/form-data" ->
        Exdeath.ProxyNode.send(proxy_node, Request.decode(request))
        {:noreply, %{state| back: proxy_node, content: content, request: request}}
      _ ->

        with {:on, response} <- CircuitBreaker.input(request)
        do
            :gen_tcp.send(socket, Response.decode(response))
        else
          _ ->
            Exdeath.ProxyNode.send(proxy_node, Request.decode(request))
        end

        {:noreply, %{state| back: proxy_node, request: request}}
    end
  end

  @doc """
  from frontend(client) packet to backend.
  """
  def handle_info({:tcp, socket, packet}, %{front: socket, back: back, content: nil}=state) do
    request = Request.encode(packet, true)
    |> Request.set_forwarded(socket)
    |> Request.set_host(back.conn)

    with {:on, response} <- CircuitBreaker.input(request)
    do
        :gen_tcp.send(socket, Response.decode(response))
    else
      _ ->
        Exdeath.ProxyNode.send(back, Request.decode(request))
    end
    {:noreply, %{state| request: request}}
  end

  @doc """
  from frontend(client) packet to backend.
  """
  def handle_info({:tcp, socket, packet}, %{front: socket, back: back, content: content, request: request}=state) do
    case content.type.type do
      "multipart/form-data" ->
        body = Request.encode(packet, false)
        {:ok, boundary} = Map.fetch(content.type.args, "boundary")
        request = %{request| body: request.body ++ body}

        if Request.match_multipart_boundary(body, boundary) do
          Exdeath.ProxyNode.send(back, packet)
          {:noreply, %{state| request: nil, content: nil}}
        else
          Exdeath.ProxyNode.send(back, packet)
          {:noreply, %{state| request: request}}
        end

      _ ->
        request = Request.encode(packet, true)
        |> Request.set_forwarded(socket)
        |> Request.set_host(back.conn)

        with {:on, response} <- CircuitBreaker.input(request)
        do
            :gen_tcp.send(socket, Response.decode(response))
        else
          _ ->
            Exdeath.ProxyNode.send(back, Request.decode(request))
        end

        {:noreply, %{state| request: nil, content: nil}}
    end
  end

  @doc """
  from backend packet to frontend(client).
  """
  def handle_info({:tcp, socket, packet}, %{front: front, back: %{conn: socket}, request: request}=state) do
    response = Response.encode(packet)

    CircuitBreaker.output(request, response)

    :gen_tcp.send(front, Response.decode(response))
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
