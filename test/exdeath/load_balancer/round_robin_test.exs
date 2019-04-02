defmodule Exdeath.LoadBalancer.RoundRobinTest do
  use ExUnit.Case

  alias Exdeath.ProxyNode
  alias Exdeath.LoadBalancer.RoundRobin

  test "get initial value" do
    assert %RoundRobin{index: 0} == RoundRobin.get_initial_value()
  end

  test "get cluster node" do
    round_robin = RoundRobin.get_initial_value()
    hosts = [
      %ProxyNode{ host: {192, 168, 10, 1}, port: 8010 },
      %ProxyNode{ host: {192, 168, 10, 2}, port: 8010 },
      %ProxyNode{ host: {192, 168, 10, 3}, port: 8010 },
    ]

    # get node index 1 from round robin load balancer
    # increase index number
    {:ok, node, hosts, round_robin} = RoundRobin.get_node(hosts, round_robin)
    assert %ProxyNode{host: {192, 168, 10, 1}, port: 8010} == node
    assert %RoundRobin{index: 1} == round_robin

    # get node index 2 from round robin load balancer and index number change to 1
    {:ok, node, hosts, round_robin} = RoundRobin.get_node(hosts, round_robin)
    assert %ProxyNode{host: {192, 168, 10, 2}, port: 8010} == node
    assert %RoundRobin{index: 2} == round_robin

    # get node index 3 from round robin load balancer and index number change to 1
    {:ok, node, hosts, round_robin} = RoundRobin.get_node(hosts, round_robin)
    assert %ProxyNode{host: {192, 168, 10, 3}, port: 8010} == node
    assert %RoundRobin{index: 0} == round_robin

    # get node index 1 from round robin load balancer
    # increase index number
    {:ok, node, _, round_robin} = RoundRobin.get_node(hosts, round_robin)
    assert %ProxyNode{host: {192, 168, 10, 1}, port: 8010} == node
    assert %RoundRobin{index: 1} == round_robin

    # error round robin
    # index exceeds the number of nodes
    round_robin = %{round_robin| index: length(hosts)}
    {:error, message, _, _} = RoundRobin.get_node(hosts, round_robin)
    assert message == "round robin index exceeds the number of nodes."

    # set empty for cluster node.
    {:error, message, _, _} = RoundRobin.get_node([], round_robin)
    assert message == "not argment cluster nodes."

    # not round robin value or cluster node
    {:error, message, _, _} = RoundRobin.get_node(hosts, %{})
    assert message ==  "not match argument value."
    {:error, message, _, _} = RoundRobin.get_node(%{}, round_robin)
    assert message ==  "not match argument value."
  end

  test "get node host number 1" do
    round_robin = RoundRobin.get_initial_value()
    hosts = [
      %ProxyNode{ host: {192, 168, 10, 1}, port: 8010 }
    ]
    # get node index 1 from round robin load balancer
    {:ok, node, hosts, round_robin} = RoundRobin.get_node(hosts, round_robin)
    assert %ProxyNode{host: {192, 168, 10, 1}, port: 8010} == node
    assert %RoundRobin{index: 0} == round_robin

    {:ok, node, _, round_robin} = RoundRobin.get_node(hosts, round_robin)
    assert %ProxyNode{host: {192, 168, 10, 1}, port: 8010} == node
    assert %RoundRobin{index: 0} == round_robin
  end
end
