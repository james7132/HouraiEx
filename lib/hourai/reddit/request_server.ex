defmodule Hourai.Reddit.RequestServer do

  use GenServer

  require Logger

  # Client calls

  def start_link(%{} = config) do
    GenServer.start_link(__MODULE__, config, name: {:global, :reddit})
  end

  def fetch(endpoint) do
    GenServer.call({:global, :reddit}, {:fetch, endpoint}, 600000)
  end

  # Server callbacks

  def init(%{} = config) do
    {token, time} = get_oauth_token(config)
    rate_limit = %{
      strategy: :pace,
      used: 0,
      remaining: 600,
      reset: Timex.zero()
    }
    auth = %{
      config: config,
      token: token,
      refresh_time: time
    }
    {:ok, {rate_limit, auth}}
  end

  def handle_call({:fetch, endpoint}, _from, {rate_limit, auth}) do
    check_rate_limit(rate_limit)
    auth = refresh_token(auth)
    response = request(endpoint, auth.token)
    rate_limit = update_rate_limit(rate_limit, response)
    json = response |> Map.get(:body) |> Poison.decode |> ok
    IO.inspect rate_limit
    {:reply, json, {rate_limit, auth}}
  end

  defp update_rate_limit(rate_limit, response) do
    hdrs = response.headers
    {remaining, _} = Integer.parse(hdrs["x-ratelimit-remaining"])
    {used, _} = Integer.parse(hdrs["x-ratelimit-used"])
    {reset, _} = Integer.parse(hdrs["x-ratelimit-reset"])
    reset_time = Timex.shift(Timex.now(), seconds: reset)

    rate_limit
    |> Map.put(:used, used)
    |> Map.put(:remaining, remaining)
    |> Map.put(:reset, reset_time)
  end

  defp check_rate_limit(rate_limit) do
    if Timex.before?(Timex.now(), rate_limit.reset) do
      delta = Timex.diff(Timex.now(), rate_limit.reset, :milliseconds) * -1
      if rate_limit.remaining <= 0 do
        Logger.warn("Reddit API rate limit exceeded. Waiting #{delta}ms until available...")
        Process.sleep(delta)
      else
        if Map.get(rate_limit, :strategy, true) do
          Process.sleep(round(delta / rate_limit.remaining))
        end
      end
    end
  end

  defp refresh_token(auth) do
    if Timex.after?(Timex.now(), auth.refresh_time) do
      Logger.debug "Refreshing reddit OAuth token..."
      {token, refresh_time} = get_oauth_token(auth.config)
      %{auth | token: token, refresh_time: refresh_time}
    else
      auth
    end
  end

  defp get_oauth_token(config) do
    token =
      request_oauth_token(config).body
      |> Poison.decode
      |> ok
      |> Map.get("access_token")
    {token, Timex.shift(Timex.now, hours: 1)}
  end

  defp request_oauth_token(config) do
    params = %{
      "grant_type": "password",
      "username": config[:user],
      "password": config[:pass],
    }

    HTTPotion.post "https://ssl.reddit.com/api/v1/access_token", [
      body: query(params),
      headers: [
        "User-Agent": "hourai-test/0.1 by james7132",
        "Content-Type": "application/x-www-form-urlencoded"
      ],
      basic_auth: {config[:client_id], config[:secret]}
    ]
  end

  defp request(endpoint, token) do
    HTTPotion.get("https://oauth.reddit.com/" <> endpoint, [headers: [
      "User-Agent": "hourai-test/0.1 by james7132",
      "Authorization": "Bearer #{token}"
    ]])
  end

  defp query(opts) do
    opts
    |> Enum.map(fn {key, value} -> "#{key}=#{URI.encode_www_form(value)}" end)
    |> Enum.join("&")
  end

  defp ok({:ok, result}), do: result

end
