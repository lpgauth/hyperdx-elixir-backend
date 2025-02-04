defmodule Hyperdx.Backend do
  @behaviour :gen_event

  @buffer_limit 10

  @impl true
  def init({__MODULE__, :hyperdx}) do
    Hyperdx.init()
    {:ok, configure(:hyperdx, [])}
  end

  @impl true
  def handle_call({:configure, opts}, %{name: name} = state) do
    {:ok, :ok, configure(name, opts, state)}
  end

  # Handle the flush event
  @impl true
  def handle_event(:flush, state) do
    do_push(state[:buffer])
    {:ok, %{state | buffer: [], buffer_size: 0}}
  end

  @impl true
  def handle_event({_, gl, _}, state) when node(gl) != node() do
    {:ok, state}
  end

  @impl true
  def handle_event({lvl, _gl, {Logger, msg, ts, metadata}}, state) do
    updated_state =
      if log_level_matches?(fix_level(lvl), state.level) do
        json_line = Hyperdx.Formatter.format(lvl, msg, ts, metadata)
        push(state, json_line)
      else
        state
      end

    {:ok, updated_state}
  end

  def fix_level(:warn), do: :warning
  def fix_level(level), do: level

  @impl true
  def terminate(reason, state) do
    IO.warn("Terminate HyperDX backend: Reason: #{inspect(reason)}")
    do_push(state[:buffer])
    :ok
  end

  # We still can hold more logs before sending bulk api request
  defp push(%{buffer_size: size} = state, payload) when size < @buffer_limit do
    %{state | buffer: [payload | state.buffer], buffer_size: size + 1}
  end

  # Our buffer is full, let's push them to hyperdx
  defp push(%{buffer_size: size} = state, payload) when size === @buffer_limit do
    do_push(state[:buffer])
    %{state | buffer: [payload], buffer_size: 1}
  end

  defp do_push([]), do: :ok

  defp do_push(payload) do
    Task.start(fn -> Hyperdx.send(payload) end)
  end

  defp configure(name, []) do
    default_state = %{
      name: name,
      level: Application.get_env(:logger, :level, :debug),
      buffer: [],
      buffer_size: 0
    }

    Application.get_env(:logger, name, [])
    |> Enum.into(default_state)
  end

  defp configure(_name, [level: new_level], state) do
    %{state | level: new_level}
  end

  defp configure(_name, _opts, state), do: state

  defp log_level_matches?(_lvl, nil), do: true
  defp log_level_matches?(lvl, min), do: Logger.compare_levels(lvl, min) != :lt
end
