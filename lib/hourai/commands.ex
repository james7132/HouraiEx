defmodule Hourai.Commands do

  alias Hourai.CommandParser
  alias Hourai.Schema.Discord.CustomCommand
  alias Hourai.Schema.Discord.BlacklistedUser
  alias Hourai.Commands.Admin
  alias Hourai.Commands.Custom
  alias Hourai.Commands.Misc
  alias Hourai.Commands.Owner
  alias Hourai.Commands.Standard
  alias Hourai.Repo
  alias Hourai.Util
  alias Nostrum.Cache

  require Logger

  @prefix "~"

  defp parse_comment(msg) do
    case String.trim(msg.content) do
      @prefix <> content -> {:ok, content}
      _ -> {:error, "No command prefix"}
    end
  end

  defp is_valid_command(msg) do
    case Repo.get(BlacklistedUser, msg.author.id) do
      nil -> :ok
      _ -> {:error, "Blacklisted user"}
    end
  end

  def handle_message(msg) do
    {time, result} = :timer.tc fn ->
      with {:ok, command} <- parse_comment(msg),
           :ok <- is_valid_command(msg) do
        execute(command, msg)
      end
    end
    if result != :ok do
      Logger.info "Executed command '#{msg.content}' in #{time} μs"
    end
    # Send message and command handling time to monitoring
  end

  def execute(command, msg) when is_binary(command) do
    command
    |> String.trim
    |> CommandParser.split
    |> execute(msg)
  end

  def execute(["kick" | options], msg) do
    Admin.kick(msg, options)
  end

  def execute(["mute"| options], msg) do
    Admin.set_mute(msg, true, options)
  end

  def execute(["unmute" | options], msg) do
    Admin.set_mute(msg, false, options)
  end

  def execute(["deafen" | options], msg) do
    Admin.set_deaf(msg, true, options)
  end

  def execute(["undeafen" | options], msg) do
    Admin.set_deaf(msg, false, options)
  end

  def execute(["avatar" | options], msg) do
    Standard.avatar(msg, options)
  end

  def execute(["choose" | options], msg) do
    Standard.choose(options, msg)
  end

  def execute(["echo" | options], msg) do
    Standard.echo(msg, options)
  end

  def execute(["hash", alg | options], msg) do
    Standard.hash(msg, alg, options)
  end

  def execute(["invite" | _], msg) do
    Standard.invite(msg)
  end

  def execute(["serverinfo"], msg) do
    Standard.serverinfo(msg)
  end

  def execute(["whois" | options], msg) do
    Standard.whois(msg, options)
  end

  def execute(["server", "permissions" | _], msg) do
    Standard.server_permissions(msg)
  end

  # Nitori Misc Commands
  def execute(["lmgtfy" | options], msg) do
    Misc.lmgtfy(msg, options)
  end

  def execute(["shrug" | _], msg) do
    Misc.shrug(msg)
  end

  def execute(["blah" | _], msg) do
    Misc.blah(msg)
  end

  def execute(["lenny" | _], msg) do
    Misc.lenny(msg)
  end

  def execute(["8ball" | _], msg) do
    Misc.eight_ball(msg)
  end

  # Blacklist commands
  def execute(["blacklist", "user", change | _], msg) do
    Owner.blacklist_user(msg, change)
  end

  # Custom commands
  def execute(["command", name], msg) do
    Custom.delete_command(msg, name)
  end

  def execute(["command", name | response], msg) do
    Custom.add_or_update_command(msg, name, response)
  end

  def execute([prefix | _], msg) do
    with {:ok, guild} <- Cache.Guild.GuildServer.get(channel_id: msg.channel_id),
          command when not is_nil(command)  <- Repo.get_by(CustomCommand, guild_id: guild.id, name: prefix) do
      Util.reply(command.response, msg)
    end
  end

end
