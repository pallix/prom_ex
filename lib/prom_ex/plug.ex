unless Code.ensure_loaded?(Plug) do
  raise "Attempting to use PromEx.Plug when Plug has not been installed"
end

defmodule PromEx.Plug do
  @moduledoc """
  Use this plug in your Endpoint file to expose your metrics. The following options are supported by this plug:

  - `path`: The path through which your metrics can be accessed (default is "/metrics")

  If you need to have some sort of access control around your metrics endpoint, I would suggest looking at another
  library that I maintain called `Unplug` (https://hex.pm/packages/unplug). Using `Unplug` you can skip over this plug if
  some sort of requirement is not fulfilled. For example, if you wanted to configure the metrics endpoint to
  only be accessible if the request has an Authorization header that matches a configured environment variable you
  could do something like so using `Unplug`:

  ```
  defmodule MyApp.UnplugPredicates.SecureMetricsEndpoint do
    @behaviour Unplug.Predicate

    @impl true
    def call(conn, env_var) do
      auth_header = Plug.Conn.get_req_header(conn, "authorization")

      System.get_env(env_var) == auth_header
    end
  end
  ```

  Which can then be used in your `endpoint.ex` file like so:

  ```
  plug Unplug,
    if: {MyApp.UnplugPredicates.SecureMetricsEndpoint, "PROMETHEUS_AUTH_SECRET"},
    do: PromEx.Plug
  ```

  The reason that this functionality is not part of PromEx itself is that how you chose to configure the visibility
  of the metrics route is entirely up to the user and so it felt as though this plug would be over complicated by
  having to support application config, environment variables, etc. And given that `Unplug` exists for this purpose,
  it is the recommended tool for the job.
  """

  alias Plug.Conn

  @behaviour Plug

  @impl true
  def init(opts) do
    %{
      metrics_path: Keyword.get(opts, :path, "/metrics")
    }
  end

  @impl true
  def call(%Conn{request_path: metrics_path} = conn, %{metrics_path: metrics_path}) do
    metrics = PromEx.get_metrics()

    conn
    |> Conn.put_resp_content_type("text/plain")
    |> Conn.send_resp(200, metrics)
    |> Conn.halt()
  end

  def call(conn, _opts) do
    conn
  end
end
