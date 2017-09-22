defmodule Hourai.Commands.Supervisor do

  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_arg) do
    import Supervisor.Spec

    children =
      for i <- 1..System.schedulers_online do
        worker(Hourai.Commands.Consumer, [], id: i)
      end

    supervise(children, strategy: :one_for_one)
  end

end
