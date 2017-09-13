defmodule Hourai.Consumer do

  use Nostrum.TaskedConsumer

  alias Hourai.Commands

  def start_link do
    TaskedConsumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, {msg}, _}) do
    Commands.handle_message(msg)
  end

  def handle_event(_) do
    :noop
  end

end
