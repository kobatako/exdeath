defmodule Exdeath.Behaviour do
  @type value :: any()
  @type proxyNode :: Exdeath.ProxyNode

  @doc """
    get initial value for load balancer
  """
  @callback get_initial_value() :: value()

  @doc """
    get node from load balancer.
    return the cluster node and cluster nodes.
  """
  @callback get_node([proxyNode()], value())
              :: {:ok, proxyNode(), [proxyNode()], value()}
              |  {:error, String.t(), [proxyNode()], value()}
end
