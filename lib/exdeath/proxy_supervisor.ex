defmodule Exdeath.ProxySupervisor do

  use Supervisor

  def start_link(listen) do
    Supervisor.start_link(__MODULE__, listen, name: __MODULE__)
  end

  def init(listen) do
    # background
    hosts = [
      %Exdeath.ProxyNode{
        host: {192, 168, 33, 61},
        port: 8010,
      }
    ]
    spawn(__MODULE__, :start_workers, [listen, hosts])
    {:ok, { {:one_for_one, 6, 60}, []} }
  end

  def start_workers(listen, hosts) do
    for _ <- 1..50000, do: start_worker(listen, hosts)
  end

  def start_worker(listen, hosts) do
    pid = make_ref()
    child_spec = %{
      id: pid,
      start: {Exdeath.Proxy, :start_link, [listen, hosts, pid]},
      restart: :temporary,
      shutdown: :brutal_kill,
      type: :worker
    }
    Supervisor.start_child(__MODULE__, child_spec)
  end
end
