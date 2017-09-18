defmodule Hourai.Commands.Owner do

  use Hourai.CommandModule

  submodule Hourai.Commands.Owner.Blacklist

end

defmodule Hourai.Commands.Owner.Blacklist do

  use Hourai.CommandModule

  @prefix "blacklist"
  submodule Hourai.Commands.Owner.Blacklist.User

end

defmodule Hourai.Commands.Owner.Blacklist.User do

  use Hourai.CommandModule

  alias Hourai.Schema.Discord.BlacklistedUser
  alias Hourai.Precondition
  alias Hourai.Repo
  alias Hourai.Util

  @prefix "user"

  command "+", do: blacklist_user(context, true)
  command "-", do: blacklist_user(context, false)

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

