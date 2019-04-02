defmodule Exdeath.LoadBalancer.RoundRobin do

  @behaviour Exdeath.Behaviour

  defstruct [ index: 0 ]

  @impl Exdeath.Behaviour
  def get_initial_value() do
    %__MODULE__{}
  end

  @impl Exdeath.Behaviour
  def get_node([], round_robin) do
    {:error, "not argment cluster nodes.", [], round_robin}
  end
  def get_node(nodes, %{index: index}=round_robin) when length(nodes) <= index do
    {:error, "round robin index exceeds the number of nodes.", nodes, round_robin}
  end

  def get_node(nodes, %{index: index}=round_robin) when is_list(nodes) do
    {:ok, node} = Enum.fetch(nodes, index)
    {:ok, node, nodes, %{round_robin | index: index_count(round_robin.index + 1, nodes)}}
  end

  def get_node(nodes, value) do
    {:error, "not match argument value.", nodes, value}
  end

  defp index_count(index, node) do
    rem(index, length(node))
  end
end
