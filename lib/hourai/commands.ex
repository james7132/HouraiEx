defmodule Hourai.Commands do

  alias Hourai.Util
  alias Hourai.Constants
  alias Hourai.Precondition
  alias Hourai.Permissions
  alias Hourai.Schema.Discord.CustomCommand
  alias Hourai.Schema.Discord.BlacklistedUser
  alias Hourai.Repo
  alias Nostrum.Cache

  require Logger

  @lenny [
    "( ͡° ͜ʖ ͡°)",
    "( ͠° ͟ʖ ͡°)",
    "ᕦ( ͡° ͜ʖ ͡°)ᕤ",
    "( ͡~ ͜ʖ ͡°)",
    "(ง ͠° ͟ل͜ ͡°)ง"
  ]

  @eight_ball [
    "It is certain.",
    "It is decidedly so.",
    "Without a doubt.",
    "Yes, definitely.",
    "You may rely on it.",
    "As I see it, yes.",
    "Most likely.",
    "Outlook good.",
    "Yes.",
    "Signs point to yes.",
    "Reply hazy try again...",
    "Ask again later...",
    "Better not tell you now...",
    "Cannot predict now...",
    "Concentrate and ask again...",
    "Don't count on it.",
    "My reply is no.",
    "My sources say no.",
    "Outlook not so good.",
    "Very doubtful.",
    "Why not?"
  ]

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
    |> String.split
    |> execute(msg)
  end

  def execute(["echo" | options], msg) do
    options
    |> Enum.join(" ")
    |> Util.reply(msg)
  end

  def execute(["choose" | options], msg) do
    Util.reply("I choose #{Enum.random(options)}!", msg)
  end

  def execute(["invite" | _], msg) do
    Util.reply("Use this link to add me to your server: https://discordapp.com/oauth2/authorize?client_id=208460637368614913&scope=bot&permissions=0xFFFFFFFFFFFF", msg)
  end

  def execute(["avatar"| _], msg) do
    msg.mentions
    |> Enum.map(&Constants.get_avatar_url(&1))
    |> Enum.filter(fn a -> a != nil end)
    |> Enum.join("\n")
    |> Util.reply(msg)
  end

  def execute(["whois" | _], msg) do
    user = Util.get_default_target_user(msg)
    member =
      with {:ok, guild} <- Cache.Guild.GuildServer.get(channel_id: msg.channel_id),
           {:ok, guild_member} <- Util.get_guild_member(user.id, guild) do
         roles = Util.get_roles(guild, guild_member.roles)
                 |> Enum.reject(fn r -> String.contains?(r.name, "everyone") end)
         {:ok, guild_member, roles}
      end

    username = "Username: `#{Util.id_string(user)}`"
    created_on = "Created on: `#{user.id |> Util.created_on |> DateTime.to_string}`"
    avatar = Constants.get_avatar_url(user)
    case member do
      {:ok, guild_member, roles} ->
        [
          username,
          case Map.get(guild_member, :nick) do
            nil -> nil
            nick -> "Nickname: `#{nick}`"
          end,
          created_on,
          case Map.get(guild_member, :joined_at) do
            nil -> nil
            joined_at ->
              {:ok, join_date, _} = DateTime.from_iso8601(joined_at)
              "Joined on: `#{DateTime.to_string(join_date)}`"
          end,
          case roles do
            nil -> nil
            role_list -> "Roles: #{Util.codify_list(role_list, fn r -> r.name end)}"
          end,
          avatar
        ]
      {:error, _} -> [username, created_on, avatar]
    end
    |> Enum.filter(fn x -> x != nil end)
    |> Enum.join("\n")
    |> Util.reply(msg)
  end

  def execute(["serverinfo"], msg) do
    with {:ok, guild} <- Precondition.in_guild(msg),
         {:ok, owner} <- Cache.UserCache.get(id: guild.owner_id) do
      response ="""
      \nName: `#{guild.name}`
      ID: `#{guild.id}`
      Owner: `#{Util.id_string(owner)}`
      Region: `#{guild.region}`
      Members: `#{guild.member_count}`
      """
      response =
        if Enum.any?(guild.roles),
        do: response <> "Roles: #{Util.guild_role_list(guild)}\n",
        else: response
      response =
        if Enum.any?(Enum.filter(guild.channels, fn c -> c.type != 0 end)),
        do: response <> "Text Channels: #{Util.guild_text_channel_list(guild)}\n",
        else: response
      response =
        if Enum.any?(Enum.filter(guild.channels, fn c -> c.type != 2  end)),
        do: response <> "Voice Channels: #{Util.guild_voice_channel_list(guild)}\n",
        else: response
      icon_url = Constants.guild_icon_url(guild)
      response = if icon_url, do: response <> icon_url, else: response
      Util.reply(response, msg)
    end
  end

  def execute(["server", "permissions" | _], msg) do
    with {:ok, guild} <- Precondition.in_guild(msg) do
      user = Util.get_default_target_user(msg)
      with {:ok, member} <- Util.get_guild_member(user.id, guild) do
        guild
        |> Util.get_guild_permission(member.roles)
        |> Permissions.get_permissions
        |> Util.codify_list(fn perm ->
            perm
            |> Atom.to_string
            |> String.replace("_", " ")
            |> String.capitalize
          end)
        |> Util.reply(msg)
      end
    end
  end

  # Nitori Misc Commands
  def execute(["lmgtfy" | options], msg) do
    Util.reply("https://lmgtfy.com/?q=#{options |> Enum.join(" ") |> URI.encode}", msg);
  end

  def execute(["shrug" | _], msg) do
    Util.reply("¯\\\\\\\_(ツ)_/¯", msg);
  end

  def execute(["blah" | _], msg) do
    Util.reply("Blah to you too, #{Util.mention(msg.author)}.", msg);
  end

  def execute(["lenny" | _], msg) do
    Util.reply(Enum.random(@lenny), msg);
  end

  def execute(["8ball" | _], msg) do
    Util.reply(Enum.random(@eight_ball), msg);
  end

  # Hash Commands
  def execute(["hash", alg | options], msg) do
    hash_alg =
      case alg do
        "md5" -> :md5
        "sha128" -> :sha
        "sha256" -> :sha256
        "sha512" -> :sha512
      end
    options
    |> Enum.join(" ")
    |> (&:crypto.hash(hash_alg, &1)).()
    |> Base.encode16(case: :lower)
    |> Util.reply(msg)
  end

  # Blacklist commands
  def execute(["blacklist", "user", change | _], msg) do
    with :ok <- Precondition.author_is_owner(msg) do
      case change do
        "+" ->
          Repo.insert_all(BlacklistedUser,
                          Enum.map(msg.mentions, fn user -> %{id: user.id} end))
        "-" ->
          Enum.each(msg.mentions, fn user ->
            Repo.delete(%BlacklistedUser{id: user.id})
          end)
      end
      Util.reply(":thumbsup:", msg)
    end
  end

  # Custom commands
  def execute(["command", name], msg) do
    with {:ok, guild} <- Precondition.in_guild(msg) do
      case Repo.get_by(CustomCommand, guild_id: guild.id, name: name) do
        nil ->
          Util.reply("Command `#{name}` does not exist!", msg)
        command ->
          Repo.delete(command)
          Util.reply("Command `#{name}` successfully deleted.", msg)
      end
    end
  end

  def execute(["command", name | response], msg) do
    with {:ok, guild} <- Precondition.in_guild(msg) do
      result = %CustomCommand{}
                |> CustomCommand.changeset(%{
                  guild_id: guild.id,
                  name: name,
                  response: Enum.join(response, " ")
                })
                |> Repo.insert_or_update
      case result do
        {:ok, model} ->
          Util.reply("Command `#{model.name}` created with response \"#{model.response}\"", msg)
        {:error, error} ->
          Util.reply("Something went wrong: '#{error}'", msg)
      end
    end
  end

  def execute([prefix | _], msg) do
    with {:ok, guild} <- Cache.Guild.GuildServer.get(channel_id: msg.channel_id),
          command when not is_nil(command)  <- Repo.get_by(CustomCommand, guild_id: guild.id, name: prefix) do
      Util.reply(command.response, msg)
    end
  end

end
