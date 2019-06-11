defmodule Exdeath.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    ip = {0, 0, 0, 0}
    port = 4040
    {:ok, listen} = :gen_tcp.listen(port, [:binary, packet: :raw, active: true, ip: ip])
    children = [
      supervisor(Exdeath.ProxySupervisor, [listen], name: ProxySupervisor),
      supervisor(Exdeath.Filter.CircuitBreaker, [], name: CircuitBreaker)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
