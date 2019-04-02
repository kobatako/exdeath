defmodule Exdeath.LoadBalancer do
  @moduledoc """
    exdeath load balancer.
    get requesting node from cluster node.
    load balancer module is setting start_link argument.
  """

  use GenServer

  def start_link(pid, module) do
    GenServer.start_link(__MODULE__, {module, module.get_initial_value()}, name: {:global, pid})
  end

  def init(value) do
    {:ok, value}
  end

  @doc """
    handle call get node from cluster nodes.
  """
  def handle_call({:get_node, nodes}, _from, {module, value}) do
    {:ok, node, _, value} = module.get_node(nodes, value)
    {:reply, node, {module, value}}
  end

  def get_node(nil, _) do
    {:error, "not argument gen server pid"}
  end
  def get_node(_, []) do
    {:error, "not argument nodes"}
  end

  @doc """
    get_node is load balancer interface.
    get node from arugment nodes.
  """
  def get_node(pid, nodes) do
    GenServer.call(pid, {:get_node, nodes})
  end
end
