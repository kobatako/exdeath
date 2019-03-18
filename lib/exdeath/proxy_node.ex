defmodule Exdeath.ProxyNode do
  defstruct [ :host, :port, conn: nil ]

  def set_connect(proxy) do
    with {:ok, conn} <- :gen_tcp.connect(proxy.host, proxy.port, [:binary, packet: 0])
    do
      {:ok, %{proxy| conn: conn}}
    else
      error ->
        error
    end
  end

  def send(%{conn: nil}, _) do
    {:error, :not_connect}
  end

  def send(proxy, packet) do
    :gen_tcp.send(proxy.conn, packet)
  end

  def close_connect(proxy) do
    :gen_tcp.close(proxy.conn)
  end
end
