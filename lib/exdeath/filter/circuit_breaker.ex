defmodule Exdeath.Filter.CircuitBreaker do
  @breaker_count 3
  @breaker_timeup 30000

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, %{}}
  end

  def input(request) do
    GenServer.call(__MODULE__, {:check, request})
  end

  def output(request, response) do
    response_status(request, response)
  end

  defp response_status(request, %{code: code}=response) when 500 <= code and code <= 599 do
    countup(request, response)
  end

  defp response_status(request, %{code: code}=response) when 400 <= code and code <= 499 do
    countup(request, response)
  end
  defp response_status(_, _) do
    {:ok}
  end

  defp countup(%{path: path}, response) do
    GenServer.cast(__MODULE__, {:countup, path, response})
  end

  def handle_call({:check, request}, _from, status) do
    {:reply, check(request, status), status}
  end

  def handle_cast({:countup, path, response}, status) do
    status = path_count(status, path)
    |> breaker(path, response)
    {:noreply, status}
  end

  def handle_cast({:breaker_off, path}, status) do
    with {:ok, %{breaker: :on}} <- Map.fetch(status, path)
    do
      {:noreply, Map.delete(status, path)}
    else
      _ ->
        {:noreply, status}
    end
  end

  defp path_count(status, path) do
    with {:ok, %{count: count}=data} <- Map.fetch(status, path)
    do
      %{status| path => %{data| count: count + 1}}
    else
      :error ->
        Map.put(status, path, %{count: 1, breaker: :off, response: nil})
    end
  end

  defp breaker(status, path, response) do
    with {:ok, %{count: count}=data} when @breaker_count <= count <- Map.fetch(status, path)
    do
      spawn(__MODULE__, :breaker_off, [path])
      %{status| path => %{data| breaker: :on, response: response}}
    else
      _ ->
        status
    end
  end

  defp check(%{path: path}, status) do
    with {:ok, %{breaker: :on, response: response}} <- Map.fetch(status, path)
    do
      {:on, response}
    else
      _ ->
        {:off, :not_response}
    end
  end

  def breaker_off(path) do
    :timer.sleep(@breaker_timeup)
    GenServer.cast(__MODULE__, {:breaker_off, path})
  end
end
