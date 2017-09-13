defmodule Hourai.Commands.Admin do

  alias Hourai.Precondition
  alias Hourai.Util
  alias Nostrum.Api

  def kick(msg) do
    with {:ok, _, _} <- Precondition.has_guild_permission(msg, Util.me(), :kick_members),
         {:ok, guild, _} <- Precondition.has_guild_permission(msg, msg.author, :kick_members) do
     msg.mentions
     |> api_action_per_user(fn user ->
         Api.remove_member(guild.id, user.id)
       end)
     |> parse_results("kicked", "user")
     |> Util.reply(msg)
    end
  end

  def set_mute(msg, state) do
    with {:ok, _, _} <- Precondition.has_guild_permission(msg, Util.me(), :mute_members),
         {:ok, guild, _} <- Precondition.has_guild_permission(msg, msg.author, :mute_members) do
      action = if state, do: "muted", else: "unmuted"
      modify_user(msg, guild, action , %{mute: state})
    end
  end

  def set_deaf(msg, state) do
    with {:ok, _, _} <- Precondition.has_guild_permission(msg, Util.me(), :deafen_members),
         {:ok, guild, _} <- Precondition.has_guild_permission(msg, msg.author, :deafen_members) do
      action = if state, do: "deafened", else: "undeafened"
      modify_user(msg, guild, action, %{deaf: state})
    end
  end

  defp modify_user(msg, guild ,action, opts) do
    msg.mentions
    |> api_action_per_user(fn user ->
      Api.modify_member(guild.id, user.id, opts)
      end)
    |> parse_results(action, "user")
    |> Util.reply(msg)
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
