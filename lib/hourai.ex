defmodule Hourai do
  use Application

  def start(_, _) do
    import Supervisor.Spec

    children = [
      supervisor(Hourai.Repo, [])
    ]

    children = children ++
      for i <- 1..System.schedulers_online, do: worker(Hourai.Consumer, [], id: i)

    Supervisor.start_link(children, strategy: :one_for_one)
  end

end
