defmodule Hourai.Commands.Admin do

  alias Hourai.Precondition
  alias Hourai.CommandParser
  alias Hourai.Util
  alias Nostrum.Api
  alias Nostrum.Struct.User

  def kick(msg, options) do
    with {:ok, guild} <- check_permissions(msg, :kick_members) do
      get_users(options, guild)
      |> api_action_per_user(fn user ->
          Api.remove_member(guild.id, user.id)
        end)
      |> parse_results("kicked", "user")
      |> Util.reply(msg)
    end
  end

  def set_mute(msg, state, options) do
    with {:ok, guild} <- check_permissions(msg, :mute_members) do
      action = if state, do: "muted", else: "unmuted"
      modify_users(options, guild, action , %{mute: state})
      |> Util.reply(msg)
    end
  end

  def set_deaf(msg, state, options) do
    with {:ok, guild} <- check_permissions(msg, :deafen_members) do
      action = if state, do: "deafened", else: "undeafened"
      modify_users(options, guild, action, %{deaf: state})
      |> Util.reply(msg)
    end
  end

  def set_nickname(msg, nickname, options) do
    with {:ok, guild} <- check_permissions(msg, :manage_nicknames) do
      modify_users(options, guild, "nicknamed", %{nick: nickname})
      |> Util.reply(msg)
    end
  end

  defp check_permissions(msg, permission) do
    with {:ok, _, _} <- Precondition.has_guild_permission(msg, Util.me(), permission),
         {:ok, guild, _} <- Precondition.has_guild_permission(msg, msg.author, permission) do
      {:ok, guild}
    end
  end

  defp get_users(options, guild) do
    options
    |> Enum.map(&CommandParser.parse_user(&1, guild.members))
    |> Enum.filter(&match?(%User{}, &1))
  end

  defp modify_users(options, guild ,action, modify_opts) do
    get_users(options, guild)
    |> api_action_per_user(fn user ->
      Api.modify_member(guild.id, user.id, modify_opts)
      end)
    |> parse_results(action, "user")
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
