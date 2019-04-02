defmodule Exdeath.ClusterTest do
  use ExUnit.Case

  alias Exdeath.Cluster
  alias Exdeath.ProxyNode
  alias Exdeath.LoadBalancer.RoundRobin

  test "add node" do
    cluster = Cluster.new_cluster()

    host1 = %ProxyNode{host: {192, 168, 10, 1}, port: 8010}
    cluster = Cluster.add_node(cluster, host1)
    assert cluster.nodes == [host1]

    host2 = %ProxyNode{host: {192, 168, 10, 2}, port: 8010}
    cluster = Cluster.add_node(cluster, host2)
    assert cluster.nodes == [host1, host2]
  end

  test "get node" do
    host1 = %ProxyNode{host: {192, 168, 10, 1}, port: 8010}
    host2 = %ProxyNode{host: {192, 168, 10, 2}, port: 8010}

    cluster = Cluster.new_cluster()
    |> Cluster.add_node(host1)
    |> Cluster.add_node(host2)
    |> Cluster.set_load_balancer(RoundRobin)

    res_host = Cluster.get_node(cluster)
    assert host1 == res_host
    res_host = Cluster.get_node(cluster)
    assert host2 == res_host
    res_host = Cluster.get_node(cluster)
    assert host1 == res_host
  end

  test "not response node" do
    cluster = Cluster.new_cluster()
    {:error, message, _} = Cluster.get_node(cluster)
    assert message == "not set nodes"

    host1 = %ProxyNode{host: {192, 168, 10, 1}, port: 8010}
    cluster = Cluster.add_node(cluster, host1)
    {:error, message, _} = Cluster.get_node(cluster)
    assert message == "not set load_balancer"

    {:error, message, _} = Cluster.get_node(%{load_balancer: {}, nodes: {}})
    assert message == "not match cluster value"

  end
end
