defmodule Exdeath.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    children = [
      worker(Exdeath.Receiver, [], name: Receiver)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
