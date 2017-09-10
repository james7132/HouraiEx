defmodule Hourai.Commands do

  alias Hourai.Util
  alias Hourai.Constants
  alias Nostrum.Cache

  require Logger

  defp valid_command?(msg) do
    String.starts_with?(msg.content, ["~"])
  end

  def handle_message(msg) do
    IO.inspect msg
    if valid_command?(msg) do
      #IO.inspect msg
      case msg.content do
        "~" <> content ->
          {time, _} =:timer.tc fn ->
            content
            |> String.trim
            |> String.split
            |> execute(msg)
          end
          Logger.info "Executed command in #{time} μs"
        _ ->
          :ignore
      end
    end
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

  def execute(["serverinfo"], msg) do
    {:ok, guild} = Cache.Guild.GuildServer.get(channel_id: msg.channel_id)
    {:ok, owner} = Cache.UserCache.get(id: guild.owner_id)
    response ="""
    \nName: `#{guild.name}`
    ID: `#{guild.id}`
    Owner: `#{Util.id_string(owner)}`
    Region: `#{guild.region}`
    Members: `#{guild.member_count}`
    """
    if Enum.any?(guild.roles) do
      response = response <> "Roles: #{Util.guild_role_list(guild)}\n"
    end
    if Enum.any?(Enum.filter(guild.channels, fn c -> c.type != 0 end)) do
      response = response <> "Text Channels: #{Util.guild_text_channel_list(guild)}\n"
    end
    if Enum.any?(Enum.filter(guild.channels, fn c -> c.type != 2  end)) do
      response = response <> "Voice Channels: #{Util.guild_voice_channel_list(guild)}\n"
    end
    icon_url = Constants.guild_icon_url(guild)
    if icon_url do
      response = response <> icon_url
    end
    Util.reply(response, msg)
  end

  # Hash Commands
  def execute(["hash", "md5" | options], msg) do
    hash(:md5, options, msg)
  end

  def execute(["hash", "sha128" | options], msg) do
    hash(:sha, options, msg)
  end

  def execute(["hash", "sha256" | options], msg) do
    hash(:sha256, options, msg)
  end

  def execute(["hash", "sha512" | options], msg) do
    hash(:sha512, options, msg)
  end

  # Noop match
  def execute(_, _) do
    :ok
  end

  def hash(alg, options, msg) do
    options
    |> Enum.join(" ")
    |> (&:crypto.hash(alg, &1)).()
    |> Base.encode16(case: :lower)
    |> Util.reply(msg)
  end

end
