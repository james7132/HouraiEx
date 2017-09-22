defmodule Hourai do
  use Application

  def start(_, _) do
    import Supervisor.Spec

    Supervisor.start_link([
      supervisor(Hourai.Repo, []),
      supervisor(Hourai.Reddit.Supervisor, []),
      supervisor(Hourai.Commands.Supervisor, []),
    ], strategy: :one_for_one)
  end

end
