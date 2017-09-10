defmodule Hourai.Util do

  alias Nostrum.Api
  #alias Nostrum.Cache

  def reply(content, msg) do
    Task.async fn ->
      Api.create_message(msg.channel_id, content)
    end
  end

  def guild_role_list(guild) do
    guild.roles
    |> Enum.drop(1)
    |> Enum.reverse
    |> codify_list(fn r -> r.name end)
  end

  def guild_text_channel_list(guild) do
    guild_channel_list(guild, 0)
  end

  def guild_voice_channel_list(guild) do
    guild_channel_list(guild, 2)
  end

  defp guild_channel_list(guild, type) do
    guild.channels
    |> Enum.filter(fn c -> c.type == type end)
    |> codify_list(fn c -> c.name end)
  end

  def codify_list(list, str_fn) do
    list
    |> Enum.map(str_fn)
    |> Enum.map(fn val -> "`#{val}`" end)
    |> Enum.join(" ")
  end

  def id_string(user) do
    "#{user.username}##{user.discriminator} (#{user.id})"
  end

  #def to_users(user_set) do
    #Enum.map fn usr ->
      #case usr do
        ##id when is_int(usr) ->
          ##usr_id = id
        #"<@" <> user_id <> ">" ->
          #usr_id = String.to_integer(user_id)
        ##id when is_str(usr) ->
          ##usr_id = String.to_integer(usr)
      #end
      #Cache.User.get!(usr_id)
    #end
  #end

end
