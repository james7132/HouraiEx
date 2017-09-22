defmodule Hourai.Commands do

  use Hourai.CommandService

  alias Hourai.Schema.Discord.BlacklistedUser
  alias Hourai.Repo

  require Logger

  @prefix "~"

  defp parse_comment(msg) do
    case  String.trim(msg.content) do
      @prefix <> content -> {:ok, content}
      _ -> {:not_command, "No command prefix"}
    end
  end

  defp is_valid_command(msg) do
    Repo.get(BlacklistedUser, msg.author.id) || :ok
  end

  def handle_message(msg) do
    {time, result} = :timer.tc fn ->
      with {:ok, command} <- parse_comment(msg),
           :ok <- is_valid_command(msg) do
        execute(command, msg)
        :ok
      end
    end
    case result do
      :ok -> Logger.info "Executed command '#{msg.content}'. Time: #{time} μs"
      {:error, error} ->
        Logger.error "Failed command: '#{msg.content}'. Error: '#{error}'. Time: #{time} μs"
      _ -> :noop
    end
  end

end
