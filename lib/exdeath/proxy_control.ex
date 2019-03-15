defmodule Exdeath.ProxyControl do

  use Supervisor

  def start_link(listen) do
    IO.inspect "proxy control start link"
    IO.inspect listen
    Supervisor.start_link(__MODULE__, listen, name: __MODULE__)
  end

  def init(listen) do
    IO.inspect "proxy control init"
    spawn(__MODULE__, :start_workers, [listen])
    {:ok, { {:one_for_one, 6, 60}, []} }
  end

  def start_workers(listen) do
    for _ <- 1..50000, do: start_worker(listen)
  end

  def start_worker(listen) do
    pid = make_ref()
    child_spec = %{
      id: pid,
      start: {Exdeath.Proxy, :start_link, [listen, pid]},
      restart: :temporary,
      shutdown: :brutal_kill,
      type: :worker
    }
    Supervisor.start_child(__MODULE__, child_spec)
  end
end
