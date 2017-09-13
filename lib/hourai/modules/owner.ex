defmodule Hourai.Commands.Owner do

  alias Hourai.Util
  alias Hourai.Precondition
  alias Hourai.Repo
  alias Hourai.Schema.Discord.BlacklistedUser

  def blacklist_user(msg, change) do
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

end
