defmodule Hourai.Commands.Admin do

  use Hourai.CommandModule

  alias Hourai.Precondition
  alias Hourai.CommandParser
  alias Hourai.Util
  alias Nostrum.Api
  alias Nostrum.Struct.Guild.Member

  command "kick" do
    with {:ok, guild} <- check_permissions(context, :kick_members) do
      results =
      get_users(context, guild)
      |> api_action_per_user(fn user ->
          Api.remove_member(guild.id, user.id)
        end)
      |> parse_results("kicked", "user")
      reply(context, results)
    end
  end

  # TODO(james7132): Figure a less ugly way to write this
  command "mute", do: modify_users(context, :mute_members, "muted", %{mute: true})
  command "unmute", do: modify_users(context, :mute_members, "unmuted", %{mute: false})
  command "deafen", do: modify_users(context, :deafen_members, "deafened", %{deaf: true})
  command "undeafen", do: modify_users(context, :deafen_members, "undeafened", %{deaf: false})

  defp check_permissions(context, permission) do
    msg = context.msg
    with {:ok, _, _} <- Precondition.has_guild_permission(msg, Util.me(), permission),
         {:ok, guild, _} <- Precondition.has_guild_permission(msg, msg.author, permission) do
      {:ok, guild}
    end
  end

  defp get_users(context, guild) do
    context.args
    |> Enum.map(&CommandParser.parse_guild_member(&1, guild))
    |> Enum.map(fn member ->
        case member do
          %Member{} -> member.user
          _ -> nil
        end
      end)
    |> Enum.filter(fn x -> x end) # Filter non-matches
  end

  defp modify_users(context, permission, action, modify_opts) do
    with {:ok, guild} <- check_permissions(context, permission) do
      results =
        get_users(context, guild)
        |> api_action_per_user(&Api.modify_member(guild.id, &1.id, modify_opts))
        |> parse_results(action, "user")
      reply(context, results)
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
