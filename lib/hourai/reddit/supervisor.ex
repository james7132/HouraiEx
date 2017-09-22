defmodule Hourai.Reddit.Supervisor do

  use Supervisor

  alias Hourai.Reddit

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_arg) do
    import Supervisor.Spec

    supervise([
      worker(Reddit.RequestServer, [Application.get_env(:hourai, :reddit)]),
      worker(Reddit.Fetcher, [])
    ], strategy: :rest_for_one)
  end

end
