defmodule Exdeath.Application do
  use Application

  def start(_type, _arg) do
    Exdeath.Supervisor.start_link()
  end
end
