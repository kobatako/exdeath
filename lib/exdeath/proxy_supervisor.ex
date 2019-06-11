defmodule Exdeath.ProxySupervisor do

  alias Exdeath.Cluster
  alias Exdeath.ProxyNode
  use Supervisor

  def start_link(listen) do
    Supervisor.start_link(__MODULE__, listen, name: __MODULE__)
  end

  def init(listen) do
    # background
    cluster =
      Cluster.new_cluster()
      # |> Cluster.add_node(%ProxyNode{
      #   host: {192, 168, 33, 10},
      #   port: 4000,
      # })
      |> Cluster.add_node(%ProxyNode{
        host: {192, 168, 33, 20},
        port: 8080,
      })
      |> Cluster.set_load_balancer(
        Exdeath.LoadBalancer.RoundRobin
      )
    spawn(__MODULE__, :start_workers, [listen, cluster])
    {:ok, { {:one_for_one, 6, 60}, []} }
  end

  def start_workers(listen, cluster) do
    for _ <- 1..50000, do: start_worker(listen, cluster)
  end

  def start_worker(listen, cluster) do
    pid = make_ref()
    child_spec = %{
      id: pid,
      start: {Exdeath.Proxy, :start_link, [listen, cluster, pid]},
      restart: :temporary,
      shutdown: :brutal_kill,
      type: :worker
    }
    Supervisor.start_child(__MODULE__, child_spec)
  end
end
