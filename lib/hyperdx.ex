defmodule Hyperdx do
  require Logger

  def init() do
    :application.ensure_all_started(:buoy)
    url = :buoy_utils.parse_url(url())

    :ok =
      :buoy_pool.start(url, [
        {:pool_size, 1},
        {:socket_options,
         [
           :binary,
           {:packet, :line},
           {:packet, :raw},
           {:send_timeout, 500},
           {:send_timeout_close, true},
           {:verify, :verify_none}
         ]}
      ])
  end

  def send(messages) do
    json_lines =
      messages
      |> Enum.map(fn message ->
        decoded = Jason.decode!(message)
        updated = Map.put(decoded, :__hdx_sv, config(:service))
        Jason.encode!(updated)
      end)
      |> Enum.join("\n")
    post(json_lines, 0)
  end

  def post(_json_lines, 3), do: :ok

  def post(json_lines, n) do
    case :buoy.post(:buoy_utils.parse_url(url()), %{
           headers: default_headers(),
           body: json_lines,
           timeout: 30_000
         }) do
      {:ok, {:buoy_resp, _, _, _, _, _, 200}} ->
        :ok

      {:ok, {:buoy_resp, _, body, _, _, _, code}} ->
        Logger.warning(
          "Hyperdx API warning: Dropping Logs: HTTP response status is #{code}. Response body is: #{inspect(body)}"
        )

      {:error, reason} ->
        Logger.warning(
          "Hyperdx API warning: Dropping Logs: HTTP request failed due to: #{inspect(reason)}"
        )
        :timer.sleep(500)
        post(json_lines, n + 1)
    end
  end

  def url() do
    base_url = System.get_env("HYPERDX_BASE_URL") || "https://in.hyperdx.io/"
    "#{base_url}?hdx_platform=elixir"
  end

  def default_headers do
    [
      {"content-type", "application/json"},
      {"user-agent", "elixir-client/v#{Application.spec(:hyperdx, :vsn)}"},
      {"Authorization", "Bearer #{config(:token)}"}
    ]
  end

  def config(:token) do
    System.get_env("HYPERDX_API_KEY")
  end

  def config(:service) do
    System.get_env("OTEL_SERVICE_NAME")
  end
end
