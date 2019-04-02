defmodule Exdeath.Cluster do
  @moduledoc """

  """
  defstruct [ nodes: [], load_balancer: nil ]

  def new_cluster() do
    %__MODULE__{}
  end

  def add_node(cluster, node) do
    nodes = cluster.nodes ++ [node]
    %{cluster| nodes: nodes}
  end

  def set_load_balancer(cluster, nil)  do
    {:error, "load balancer is nil. ", cluster}
  end

  def set_load_balancer(cluster, load_balancer)  do
    {:ok, pid} = Exdeath.LoadBalancer.start_link(make_ref(), load_balancer)
    %{cluster| load_balancer: pid}
  end

  def get_node(%{nodes: []}=cluster) do
    {:error, "not set nodes", cluster}
  end
  def get_node(%{load_balancer: nil}=cluster) do
    {:error, "not set load_balancer", cluster}
  end
  def get_node(%{load_balancer: pid, nodes: nodes}) when is_list(nodes) and is_pid(pid) do
    Exdeath.LoadBalancer.get_node(pid, nodes)
  end
  def get_node(value) do
    {:error, "not match cluster value", value}
  end
end
