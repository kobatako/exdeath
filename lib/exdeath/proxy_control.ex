defmodule Exdeath.ProxyControl do
  use Supervisor
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    IO.inspect "proxy control init"
    {:ok, { {:one_for_one, 6, 3600}, [] } }
  end

  def start_child(front, back) do
    children = [
      worker(Exdeath.Proxy, [front, back], name: Proxy),
    ]
    {:ok, pid} = Supervisor.start_link(__MODULE__, children)
    IO.inspect "proxy front"
    IO.inspect pid
    IO.inspect self()
    IO.inspect front
    IO.inspect back
    {:ok, pid}
  end

  def handle_call(_, _from, state) do
    {:reply, state, state}
  end
end
