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
      worker(Exdeath.Receiver, [listen, Exdeath.ProxyControl], name: Receiver),
      supervisor(Exdeath.ProxyControl, [], name: Receiver)
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 10000)
  end
end
