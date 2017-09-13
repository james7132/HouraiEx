defmodule Hourai.Commands.Admin do

  alias Hourai.Precondition
  alias Hourai.Util
  alias Nostrum.Api

  def kick(msg) do
    with {:ok, _, _} <- Precondition.has_guild_permission(msg, Util.me(), :kick_members),
         {:ok, guild, _} <- Precondition.has_guild_permission(msg, msg.author, :kick_members) do
     msg.mentions
     |> api_action_per_user(fn user ->
         #Api.remove_member(guild.id, user.id)
         {:ok}
       end)
     |> parse_results("kicked", "user")
     |> Util.reply(msg)
    end
  end

  defp parse_results({success, failures}, action, unit) do
      response = "Successfully #{action} #{success} #{unit}s."
      case failures do
        [] -> response
        errors -> response <> "Errors:\n  #{Enum.join(errors, "\n  ")}"
      end
  end

  defp api_action_per_user(users, action) do
    users
    |> Enum.map(fn user ->
      Task.async fn ->
        action.(user)
      end
    end)
    |> Enum.reduce({0, []}, fn (task, {success, failures})->
      case Task.await(task) do
        {:ok} -> {success + 1, failures}
        error -> {success, failures ++ [Exception.message(error)]}
      end
    end)
  end

end
